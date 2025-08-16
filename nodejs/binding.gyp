{
  "targets": [
    {
      "target_name": "dds_addon",
      "sources": [ "src/addon.cpp" ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "dds-src"
      ],
      "conditions": [
        ["OS=='win'", {
          "include_dirs": [
            "C:/fastdds 3.2.2/include",
            "C:/fastdds 3.2.2/include/fastcdr",
            "C:/fastdds 3.2.2/include/fastdds"
          ],
          "libraries": [
            "<(module_root_dir)/dds-src/build/Release/ICD.lib",
            "C:/fastdds 3.2.2/lib/x64Win64VS2019/libfastdds-3.2.lib",
            "C:/fastdds 3.2.2/lib/x64Win64VS2019/libfastcdr-2.3.lib",
            "C:/fastdds 3.2.2/lib/x64Win64VS2019/foonathan_memory-0.7.3.lib"
          ],
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
        }],
        ["OS=='linux'", {
          "include_dirs": [
            "/usr/local/include",
            "/usr/local/include/fastdds",
            "/usr/local/include/fastcdr"
          ],
          "libraries": [
            "-lfastdds",
            "-lfastcdr"
          ],
          "defines": [ 
            "NAPI_DISABLE_CPP_EXCEPTIONS",
            "NAPI_VERSION=6"
          ],
          "cflags_cc": [
            "-fexceptions",
            "-frtti"
          ]
        }]
      ],
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ]
    }
  ]
}
