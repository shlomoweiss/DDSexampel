#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const platform = os.platform();
const ddsSrcDir = path.join(__dirname, '..', 'dds-src');
const buildDir = path.join(ddsSrcDir, 'build');
const originalDDSDir = path.join(__dirname, '..', '..', 'DDSmessage');

console.log('Building DDS library...');

// Function to copy file if source is newer or target doesn't exist
function copyIfNewer(src, dest) {
    if (!fs.existsSync(src)) {
        throw new Error(`Source file not found: ${src}`);
    }
    
    let shouldCopy = !fs.existsSync(dest);
    
    if (!shouldCopy) {
        const srcStats = fs.statSync(src);
        const destStats = fs.statSync(dest);
        shouldCopy = srcStats.mtime > destStats.mtime;
    }
    
    if (shouldCopy) {
        console.log(`  Copying: ${path.basename(src)}`);
        fs.copyFileSync(src, dest);
        return true;
    }
    return false;
}

// Copy source files from DDSmessage if needed (development mode)
// In npm install mode, DDSmessage won't exist and files will already be in dds-src
const ddsmessageExists = fs.existsSync(originalDDSDir);

if (ddsmessageExists) {
    console.log('Development mode: Checking source files from DDSmessage...');
    
    // Create dds-src directory if it doesn't exist
    if (!fs.existsSync(ddsSrcDir)) {
        fs.mkdirSync(ddsSrcDir, { recursive: true });
    }

    // List of files to copy from DDSmessage (excluding CMakeLists.txt)
    const filesToCopy = [
        'dds_facade.cpp',
        'dds_facade.hpp', 
        'ICD.hpp',
        'ICDCdrAux.hpp',
        'ICDCdrAux.ipp',
        'ICDPubSubTypes.cxx',
        'ICDPubSubTypes.hpp',
        'ICDTypeObjectSupport.cxx',
        'ICDTypeObjectSupport.hpp'
    ];

    let copiedFiles = 0;
    for (const fileName of filesToCopy) {
        const srcFile = path.join(originalDDSDir, fileName);
        const destFile = path.join(ddsSrcDir, fileName);
        
        if (copyIfNewer(srcFile, destFile)) {
            copiedFiles++;
        }
    }

    if (copiedFiles > 0) {
        console.log(`✓ Copied ${copiedFiles} updated source files from DDSmessage`);
    } else {
        console.log('✓ All source files are up to date');
    }
} else {
    console.log('npm install mode: Using source files from package...');
    
    // Verify required source files exist
    const requiredFiles = [
        'dds_facade.cpp',
        'ICD.hpp',
        'ICDPubSubTypes.cxx',
        'ICDTypeObjectSupport.cxx'
    ];
    
    const missingFiles = requiredFiles.filter(file => 
        !fs.existsSync(path.join(ddsSrcDir, file))
    );
    
    if (missingFiles.length > 0) {
        throw new Error(`Missing required source files: ${missingFiles.join(', ')}`);
    }
    
    console.log('✓ All required source files found');
}

// Ensure CMakeLists.txt exists (this one is specific to nodejs build)
const cmakeFile = path.join(ddsSrcDir, 'CMakeLists.txt');
if (!fs.existsSync(cmakeFile)) {
    console.log('✓ Creating CMakeLists.txt for Node.js build');
    const cmakeContent = `cmake_minimum_required(VERSION 3.15)

# Let CMake find the compilers automatically
# (removing explicit compiler settings)

project("icd_library")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)

# Platform-specific settings
if(WIN32)
    # Enable DLL creation on Windows
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    set(BUILD_SHARED_LIBS ON)
elseif(UNIX)
    # Linux/Unix settings
    set(BUILD_SHARED_LIBS ON)
    # Enable position independent code for shared libraries
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Find requirements
find_package(fastcdr REQUIRED)
find_package(fastdds 3 REQUIRED)

# Create the DLL library
add_library(ICD SHARED
    ICDPubSubTypes.cxx
    ICDTypeObjectSupport.cxx
    dds_facade.cpp
)

target_link_libraries(ICD 
    PUBLIC 
        fastcdr 
        fastdds
)

# Set include directories for users of this library
target_include_directories(ICD 
    PUBLIC 
        \${CMAKE_CURRENT_SOURCE_DIR}
        \${fastdds_INCLUDE_DIRS}
        \${fastcdr_INCLUDE_DIRS}
)
`;
    fs.writeFileSync(cmakeFile, cmakeContent);
}

// Create build directory
if (!fs.existsSync(buildDir)) {
    fs.mkdirSync(buildDir, { recursive: true });
}

process.chdir(buildDir);

try {
    if (platform === 'win32') {
        console.log('Windows detected - using CMake + MSBuild');
        
        // Configure with CMake
        execSync('cmake .. -DCMAKE_BUILD_TYPE=Release', { stdio: 'inherit' });
        
        // Build with MSBuild
        execSync('cmake --build . --config Release', { stdio: 'inherit' });
        
        // Check if the library was created
        const libPath = path.join(buildDir, 'Release', 'ICD.lib');
        const dllPath = path.join(buildDir, 'Release', 'ICD.dll');
        
        if (fs.existsSync(libPath) && fs.existsSync(dllPath)) {
            console.log('✓ DDS library built successfully');
            console.log(`  Library: ${libPath}`);
            console.log(`  DLL: ${dllPath}`);
        } else {
            throw new Error('DDS library files not found after build');
        }
        
    } else if (platform === 'linux') {
        console.log('Linux detected - using CMake + Make');
        
        // Configure with CMake
        execSync('cmake .. -DCMAKE_BUILD_TYPE=Release', { stdio: 'inherit' });
        
        // Build with Make
        execSync(`make -j${os.cpus().length}`, { stdio: 'inherit' });
        
        // Check if the library was created
        const libPath = path.join(buildDir, 'libICD.so');
        
        if (fs.existsSync(libPath)) {
            console.log('✓ DDS library built successfully');
            console.log(`  Library: ${libPath}`);
        } else {
            throw new Error('DDS library file not found after build');
        }
        
    } else {
        throw new Error(`Unsupported platform: ${platform}`);
    }
    
} catch (error) {
    console.error('❌ Failed to build DDS library:', error.message);
    process.exit(1);
}
