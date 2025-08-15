%module ICDWrapper

%{
#include "ICD.hpp"
#include "ICDPubSubTypes.hpp"
#include "ICDTypeObjectSupport.hpp"
#include "ICDCdrAux.hpp"
#include "dds_facade.hpp"
%}

// Common typemaps
%include "stdint.i"
%include "std_string.i"
%include "std_vector.i"

// Expose generated Fast DDS type(s)
%include "ICD.hpp"
%include "ICDPubSubTypes.hpp"
%include "ICDTypeObjectSupport.hpp"
%include "ICDCdrAux.hpp"
%include "dds_facade.hpp"

// Simple C facade functions - includes both legacy and new struct-based functions
%include "dds_facade.hpp"

// Inline helper to expose take with returned string (simplifies C# usage)
%inline %{
const char* dds_take_string(unsigned int* index_out) {
	static thread_local std::string storage;
	char buf[1024];
	if (dds_take(index_out, buf, (int)sizeof(buf)) == 1) {
		storage = buf;
		return storage.c_str();
	}
	return (const char*)0;
}
%}