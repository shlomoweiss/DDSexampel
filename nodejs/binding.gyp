{
  "targets": [
    {
      "target_name": "dds_addon",
      "sources": [ "src/addon.cpp" ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "C:/cpp-prj/DDSexampel/DDSmessage",
        "C:/cpp-prj/DDSexampel/DDSmessage/build",
        "C:/fastdds 3.2.2/include",
        "C:/fastdds 3.2.2/include/fastcdr",
        "C:/fastdds 3.2.2/include/fastdds"
      ],
      "libraries": [
        "C:/cpp-prj/DDSexampel/DDSmessage/build/Release/ICD.lib",
        "C:/fastdds 3.2.2/lib/x64Win64VS2019/fastdds-3.2.lib",
        "C:/fastdds 3.2.2/lib/x64Win64VS2019/fastcdr-2.3.lib",
        "C:/fastdds 3.2.2/lib/x64Win64VS2019/foonathan_memory-0.7.3.lib"
      ],
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ],
      "defines": [ 
        "NAPI_DISABLE_CPP_EXCEPTIONS",
        "NAPI_VERSION=6",
        "_WIN32_WINNT=0x0601",
        "ICD_EXPORTS"
      ],
      "msvs_settings": {
        "VCCLCompilerTool": {
          "ExceptionHandling": 1
        }
      }
    }
  ]
}
