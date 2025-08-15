#pragma once
#include <cstdint>

// Forward declaration for HelloWorld struct
namespace ICD_pkg {
    class HelloWorld;
}

#ifdef _WIN32
  #ifdef ICD_EXPORTS
    #define ICD_API __declspec(dllexport)
  #else
    #define ICD_API __declspec(dllimport)
  #endif
#else
  #define ICD_API
#endif

// Simple C façade for publishing/subscribing HelloWorld samples from C#.
// Return values: 1 success, 0 failure / no data.
extern "C" {

// Initialize (or reinitialize) DDS entities. Returns 1 on success.
ICD_API int dds_init(const char* topic_name);

// Initialize (or reinitialize) DDS entities with domain ID. Returns 1 on success.
ICD_API int dds_init_with_domain(const char* topic_name, uint32_t domain_id);

// LEGACY: Write a HelloWorld sample with index + message. Returns 1 on success.
ICD_API int dds_write(uint32_t index, const char* message);

// NEW: Write a complete HelloWorld struct. Returns 1 on success.
ICD_API int dds_write_struct(const ICD_pkg::HelloWorld* hello_world);

// LEGACY: Try take one sample. If a sample is available, fills outputs and returns 1; otherwise returns 0.
ICD_API int dds_take(uint32_t* index_out, char* message_buffer, int buffer_len);

// NEW: Take a complete HelloWorld struct. Returns 1 if data available, 0 if not.
ICD_API int dds_take_struct(ICD_pkg::HelloWorld* hello_world_out);

// Convenience: take one sample and return message as const char* (nullptr if none). Index stored in *index_out if provided.
ICD_API const char* dds_take_message(uint32_t* index_out);

// Shutdown and release all entities.
ICD_API void dds_shutdown();
}
