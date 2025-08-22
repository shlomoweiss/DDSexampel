from conan import ConanFile
from conan.tools.files import copy
import os


class ICDWrapperCppConan(ConanFile):
    name = "icdwrappercpp"
    version = "1.0.0"
    description = "ICD Wrapper C++ SWIG bindings for Windows and Linux"
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
    
    # Dependencies
    def requirements(self):
        self.requires("ddsmessage/1.0.0")
    
    # Folders
    exports = "*.md", "profiles/*"
    exports_sources = "build/Release/*", "build_linux/*", "build/*"
    
    
    def package(self):
        # Debug: Print source folder contents
        self.output.info(f"Source folder: {self.source_folder}")
        self.output.info(f"Package folder: {self.package_folder}")
        
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
        self.output.info(f"Checking Linux build dir: {linux_build_dir}")
        if os.path.exists(linux_build_dir):
            self.output.info("Found build_linux directory, copying .so files...")
            # Copy shared library files
            copy(self, "*.so*",
                 src=linux_build_dir,
                 dst=os.path.join(self.package_folder, "lib"),
                 keep_path=False)
        else:
            # Fallback to regular build directory
            build_dir = os.path.join(self.source_folder, "build")
            self.output.info(f"Checking regular build dir: {build_dir}")
            if os.path.exists(build_dir):
                self.output.info("Found build directory, copying .so files...")
                # Copy shared library files
                copy(self, "*.so*",
                     src=build_dir,
                     dst=os.path.join(self.package_folder, "lib"),
                     keep_path=False)
            else:
                self.output.warn("No build directory found for Linux binaries!")
    
    def package_info(self):
        # Set the library name
        self.cpp_info.libs = ["ICDWrapper"]
        
        # Set library and binary directories - only binaries, no includes or sources
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.bindirs = ["bin"]
