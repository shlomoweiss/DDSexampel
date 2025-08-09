#include "dds_facade.hpp"
#include "ICD.hpp"
#include "ICDPubSubTypes.hpp"

#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/publisher/Publisher.hpp>
#include <fastdds/dds/publisher/DataWriter.hpp>
#include <fastdds/dds/subscriber/Subscriber.hpp>
#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/topic/Topic.hpp>
#include <fastdds/dds/subscriber/SampleInfo.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/topic/TypeSupport.hpp>
#include <mutex>
#include <string>

using namespace eprosima::fastdds::dds;

namespace {
std::mutex g_mutex;
DomainParticipant* g_participant = nullptr;
Publisher* g_publisher = nullptr;
Subscriber* g_subscriber = nullptr;
Topic* g_topic = nullptr;
DataWriter* g_writer = nullptr;
DataReader* g_reader = nullptr;
eprosima::fastdds::dds::TypeSupport g_type; // holds HelloWorldPubSubType instance
std::string g_topic_name;

void cleanup_locked() {
    if (g_writer) { g_publisher->delete_datawriter(g_writer); g_writer = nullptr; }
    if (g_reader) { g_subscriber->delete_datareader(g_reader); g_reader = nullptr; }
    if (g_topic) { g_participant->delete_topic(g_topic); g_topic = nullptr; }
    if (g_publisher) { g_participant->delete_publisher(g_publisher); g_publisher = nullptr; }
    if (g_subscriber) { g_participant->delete_subscriber(g_subscriber); g_subscriber = nullptr; }
    if (g_participant) { DomainParticipantFactory::get_instance()->delete_participant(g_participant); g_participant = nullptr; }
}
}

extern "C" {

int dds_init(const char* topic_name) {
    std::lock_guard<std::mutex> lock(g_mutex);
    cleanup_locked();

    DomainParticipantQos pqos;
    pqos.name("ICDFacadeParticipant");
    g_participant = DomainParticipantFactory::get_instance()->create_participant(0, pqos);
    if (!g_participant) return 0;

    // Register type
    g_type = TypeSupport(new ICD_pkg::HelloWorldPubSubType());
    if (g_participant->register_type(g_type) != eprosima::fastdds::dds::RETCODE_OK) {
        cleanup_locked();
        return 0;
    }

    g_topic_name = topic_name ? topic_name : "HelloWorldTopic";
    g_topic = g_participant->create_topic(g_topic_name, g_type.get_type_name(), TOPIC_QOS_DEFAULT, nullptr, eprosima::fastdds::dds::StatusMask::none());
    if (!g_topic) { cleanup_locked(); return 0; }

    g_publisher = g_participant->create_publisher(PUBLISHER_QOS_DEFAULT, nullptr);
    if (!g_publisher) { cleanup_locked(); return 0; }

    g_writer = g_publisher->create_datawriter(g_topic, DATAWRITER_QOS_DEFAULT, nullptr, eprosima::fastdds::dds::StatusMask::none());
    if (!g_writer) { cleanup_locked(); return 0; }

    g_subscriber = g_participant->create_subscriber(SUBSCRIBER_QOS_DEFAULT, nullptr);
    if (!g_subscriber) { cleanup_locked(); return 0; }

    g_reader = g_subscriber->create_datareader(g_topic, DATAREADER_QOS_DEFAULT, nullptr, eprosima::fastdds::dds::StatusMask::none());
    if (!g_reader) { cleanup_locked(); return 0; }

    return 1;
}

int dds_write(uint32_t index, const char* message) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_writer) return 0;
    ICD_pkg::HelloWorld data;
    data.index(index);
    data.message(message ? message : "");
    return g_writer->write(&data) == eprosima::fastdds::dds::RETCODE_OK ? 1 : 0;
}

int dds_take(uint32_t* index_out, char* message_buffer, int buffer_len) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_reader) return 0;
    ICD_pkg::HelloWorld data;
    SampleInfo info;
    if (g_reader->take_next_sample(&data, &info) == eprosima::fastdds::dds::RETCODE_OK) {
        if (info.instance_state == ALIVE_INSTANCE_STATE) {
            if (index_out) *index_out = data.index();
            if (message_buffer && buffer_len > 0) {
                std::string msg = data.message();
                if ((int)msg.size() >= buffer_len) {
                    // truncate
                    msg.resize(static_cast<size_t>(buffer_len - 1));
                }
                std::memcpy(message_buffer, msg.c_str(), msg.size());
                message_buffer[msg.size()] = '\0';
            }
            return 1;
        }
    }
    return 0;
}

void dds_shutdown() {
    std::lock_guard<std::mutex> lock(g_mutex);
    cleanup_locked();
}

const char* dds_take_message(uint32_t* index_out) {
    static thread_local std::string storage;
    char buf[1024];
    if (dds_take(index_out, buf, static_cast<int>(sizeof(buf))) == 1) {
        storage = buf;
        return storage.c_str();
    }
    return nullptr;
}

// NEW: Write a complete HelloWorld struct
int dds_write_struct(const ICD_pkg::HelloWorld* hello_world) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_writer || !hello_world) return 0;
    return g_writer->write(hello_world) == eprosima::fastdds::dds::RETCODE_OK ? 1 : 0;
}

// NEW: Take a complete HelloWorld struct
int dds_take_struct(ICD_pkg::HelloWorld* hello_world_out) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_reader || !hello_world_out) return 0;
    SampleInfo info;
    if (g_reader->take_next_sample(hello_world_out, &info) == eprosima::fastdds::dds::RETCODE_OK) {
        return info.instance_state == ALIVE_INSTANCE_STATE ? 1 : 0;
    }
    return 0;
}

} // extern C
