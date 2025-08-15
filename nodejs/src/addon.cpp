#include <node_api.h>
#include <string>
#include <cstring>
#include "../../DDSmessage/dds_facade.hpp"
#include "../../DDSmessage/ICD.hpp"

// Forward declarations
napi_value Init(napi_env env, napi_value exports);

// Helper function to create a string from napi_value
std::string GetStringFromValue(napi_env env, napi_value value) {
    size_t str_len = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &str_len);
    
    std::string result(str_len, '\0');
    napi_get_value_string_utf8(env, value, &result[0], str_len + 1, &str_len);
    return result;
}

// Helper function to get uint32_t from napi_value
uint32_t GetUint32FromValue(napi_env env, napi_value value) {
    uint32_t result;
    napi_get_value_uint32(env, value, &result);
    return result;
}

// Wrapper for dds_init
napi_value DdsInit(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected topic name argument");
        return nullptr;
    }
    
    std::string topic_name = GetStringFromValue(env, args[0]);
    int result = dds_init(topic_name.c_str());
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

// Wrapper for dds_init_with_domain
napi_value DdsInitWithDomain(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "Expected topic name and domain ID arguments");
        return nullptr;
    }
    
    std::string topic_name = GetStringFromValue(env, args[0]);
    uint32_t domain_id = GetUint32FromValue(env, args[1]);
    
    int result = dds_init_with_domain(topic_name.c_str(), domain_id);
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

// Wrapper for dds_write (legacy)
napi_value DdsWrite(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "Expected index and message arguments");
        return nullptr;
    }
    
    uint32_t index = GetUint32FromValue(env, args[0]);
    std::string message = GetStringFromValue(env, args[1]);
    
    int result = dds_write(index, message.c_str());
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

// Wrapper for dds_write_struct
napi_value DdsWriteStruct(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected HelloWorld object argument");
        return nullptr;
    }
    
    // Extract index and message from JavaScript object
    napi_value index_val, message_val;
    napi_get_named_property(env, args[0], "index", &index_val);
    napi_get_named_property(env, args[0], "message", &message_val);
    
    uint32_t index = GetUint32FromValue(env, index_val);
    std::string message = GetStringFromValue(env, message_val);
    
    // Create HelloWorld struct
    ICD_pkg::HelloWorld hello_world;
    hello_world.index(index);
    hello_world.message(message);
    
    int result = dds_write_struct(&hello_world);
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

// Wrapper for dds_take (legacy)
napi_value DdsTake(napi_env env, napi_callback_info info) {
    uint32_t index_out = 0;
    char message_buffer[1024];
    
    int result = dds_take(&index_out, message_buffer, sizeof(message_buffer));
    
    napi_value return_obj;
    napi_create_object(env, &return_obj);
    
    napi_value success_val, index_val, message_val;
    napi_create_int32(env, result, &success_val);
    napi_create_uint32(env, index_out, &index_val);
    napi_create_string_utf8(env, message_buffer, NAPI_AUTO_LENGTH, &message_val);
    
    napi_set_named_property(env, return_obj, "success", success_val);
    napi_set_named_property(env, return_obj, "index", index_val);
    napi_set_named_property(env, return_obj, "message", message_val);
    
    return return_obj;
}

// Wrapper for dds_take_struct
napi_value DdsTakeStruct(napi_env env, napi_callback_info info) {
    ICD_pkg::HelloWorld hello_world_out;
    
    int result = dds_take_struct(&hello_world_out);
    
    napi_value return_obj;
    napi_create_object(env, &return_obj);
    
    napi_value success_val, index_val, message_val;
    napi_create_int32(env, result, &success_val);
    napi_create_uint32(env, hello_world_out.index(), &index_val);
    napi_create_string_utf8(env, hello_world_out.message().c_str(), NAPI_AUTO_LENGTH, &message_val);
    
    napi_set_named_property(env, return_obj, "success", success_val);
    napi_set_named_property(env, return_obj, "index", index_val);
    napi_set_named_property(env, return_obj, "message", message_val);
    
    return return_obj;
}

// Wrapper for dds_take_message
napi_value DdsTakeMessage(napi_env env, napi_callback_info info) {
    uint32_t index_out = 0;
    const char* message = dds_take_message(&index_out);
    
    napi_value return_obj;
    napi_create_object(env, &return_obj);
    
    napi_value index_val, message_val;
    napi_create_uint32(env, index_out, &index_val);
    
    if (message) {
        napi_create_string_utf8(env, message, NAPI_AUTO_LENGTH, &message_val);
    } else {
        napi_get_null(env, &message_val);
    }
    
    napi_set_named_property(env, return_obj, "index", index_val);
    napi_set_named_property(env, return_obj, "message", message_val);
    
    return return_obj;
}

// Wrapper for dds_shutdown
napi_value DdsShutdown(napi_env env, napi_callback_info info) {
    dds_shutdown();
    
    napi_value return_value;
    napi_get_undefined(env, &return_value);
    return return_value;
}

// Initialize the addon
napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "init", nullptr, DdsInit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "initWithDomain", nullptr, DdsInitWithDomain, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "write", nullptr, DdsWrite, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeStruct", nullptr, DdsWriteStruct, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "take", nullptr, DdsTake, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "takeStruct", nullptr, DdsTakeStruct, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "takeMessage", nullptr, DdsTakeMessage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "shutdown", nullptr, DdsShutdown, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)