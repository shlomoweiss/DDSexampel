from conan import ConanFile
from conan.tools.files import copy
import os


class DDSMessageConan(ConanFile):
    name = "ddsmessage"
    version = "1.0.0"
    description = "DDS Message binaries for Windows and Linux"
    author = "Your Name <your.email@domain.com>"
    license = "Proprietary"
    
    # Settings for different platforms
    settings = "os", "arch", "compiler", "build_type"
    
    # Options
    options = {
        "shared": [True, False],
    }
    default_options = {
        "shared": True,
    }
    
    # Folders
    exports = "*.md"
    exports_sources = "build/Release/*", "build_linux/*", "build/*"
    
    
    def package(self):
        # Only copy binaries - no source code or headers
        
        # Copy Windows binaries if they exist
        windows_build_dir = os.path.join(self.source_folder, "build", "Release")
        if os.path.exists(windows_build_dir):
            # Copy DLL files
            copy(self, "*.dll",
                 src=windows_build_dir,
                 dst=os.path.join(self.package_folder, "bin"),
                 keep_path=False)
            # Copy LIB files (import libraries)
            copy(self, "*.lib",
                 src=windows_build_dir,
                 dst=os.path.join(self.package_folder, "lib"),
                 keep_path=False)
        
        # Copy Linux binaries if they exist
        linux_build_dir = os.path.join(self.source_folder, "build_linux")
        if os.path.exists(linux_build_dir):
            # Copy shared library files
            copy(self, "*.so*",
                 src=linux_build_dir,
                 dst=os.path.join(self.package_folder, "lib"),
                 keep_path=False)
        else:
            # Fallback to regular build directory
            build_dir = os.path.join(self.source_folder, "build")
            if os.path.exists(build_dir):
                # Copy shared library files
                copy(self, "*.so*",
                     src=build_dir,
                     dst=os.path.join(self.package_folder, "lib"),
                     keep_path=False)
    
    def package_info(self):
        # Set the library name
        self.cpp_info.libs = ["ICD"]
        
        # Set library and binary directories - only binaries, no includes
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.bindirs = ["bin"]
