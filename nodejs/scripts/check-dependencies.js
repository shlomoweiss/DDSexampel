#!/usr/bin/env node

const os = require('os');
const fs = require('fs');
const path = require('path');

console.log('Checking FastDDS dependencies...');

const platform = os.platform();

if (platform === 'win32') {
    console.log('Windows detected');
    
    // Check for FastDDS installation paths
    const possiblePaths = [
        'C:/fastdds 3.2.2',
        'C:/Program Files/fastdds',
        'C:/Program Files (x86)/fastdds'
    ];
    
    let found = false;
    for (const checkPath of possiblePaths) {
        if (fs.existsSync(checkPath)) {
            console.log(`✓ Found FastDDS at: ${checkPath}`);
            found = true;
            break;
        }
    }
    
    if (!found) {
        console.error('❌ FastDDS not found on Windows!');
        console.error('Please install FastDDS from: https://fast-dds.docs.eprosima.com/');
        console.error('Or set FASTDDS_ROOT environment variable');
        process.exit(1);
    }
    
} else if (platform === 'linux') {
    console.log('Linux detected');
    
    // Check for FastDDS system installation
    const { execSync } = require('child_process');
    
    try {
        execSync('pkg-config --exists fastdds', { stdio: 'ignore' });
        console.log('✓ FastDDS found via pkg-config');
    } catch (error) {
        // Check common installation paths
        const includePaths = [
            '/usr/local/include/fastdds',
            '/usr/include/fastdds'
        ];
        
        let found = false;
        for (const includePath of includePaths) {
            if (fs.existsSync(includePath)) {
                console.log(`✓ Found FastDDS headers at: ${includePath}`);
                found = true;
                break;
            }
        }
        
        if (!found) {
            console.error('❌ FastDDS not found on Linux!');
            console.error('Please install FastDDS:');
            console.error('  Ubuntu/Debian: sudo apt install libfastdds-dev libfastcdr-dev');
            console.error('  Or build from source: https://fast-dds.docs.eprosima.com/');
            process.exit(1);
        }
    }
} else {
    console.error(`❌ Unsupported platform: ${platform}`);
    console.error('This package only supports Windows and Linux');
    process.exit(1);
}

console.log('✓ All dependencies check passed');
