#!/usr/bin/env node
// extract-native.js
// Script to install multiple packages for Windows and Linux platforms and extract native libraries

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
const os = require('os');

// Command line argument parsing
const args = process.argv.slice(2);
let packageNames = ['ddsmessage/1.0.0'];
let remote = 'local-conan';
let outputDir = 'native-libs';

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
    if (args[i] === '--packages' && i + 1 < args.length) {
        packageNames = args[i + 1].split(',');
        i++;
    } else if (args[i] === '--remote' && i + 1 < args.length) {
        remote = args[i + 1];
        i++;
    } else if (args[i] === '--output' && i + 1 < args.length) {
        outputDir = args[i + 1];
        i++;
    }
}

// Console colors for output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m',
    gray: '\x1b[90m'
};

// Function to write colored output
function writeColorOutput(message, color = 'white') {
    const colorCode = colors[color] || colors.white;
    console.log(`${colorCode}${message}${colors.reset}`);
}

// Function to ensure directory exists
function ensureDirectory(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        writeColorOutput(`Created directory: ${dirPath}`, 'green');
    }
}

// Function to execute shell command and get output
function executeCommand(command, args = [], options = {}) {
    return new Promise((resolve, reject) => {
        const child = spawn(command, args, {
            stdio: ['ignore', 'pipe', 'pipe'],
            ...options
        });

        let stdout = '';
        let stderr = '';

        child.stdout.on('data', (data) => {
            stdout += data.toString();
        });

        child.stderr.on('data', (data) => {
            stderr += data.toString();
        });

        child.on('close', (code) => {
            resolve({
                exitCode: code,
                stdout: stdout.trim(),
                stderr: stderr.trim()
            });
        });

        child.on('error', (error) => {
            reject(error);
        });
    });
}

// Function to get package revisions from conan list
async function getPackageRevisions(packageName, remoteName) {
    writeColorOutput(`Getting revisions for package: ${packageName}`, 'yellow');
    const command = `conan list "${packageName}#*:*#*" -r ${remoteName}`;
    writeColorOutput(`Running: ${command}`, 'gray');
    
    try {
        const result = await executeCommand('conan', ['list', `${packageName}#*:*#*`, '-r', remoteName]);
        
        if (result.exitCode !== 0) {
            writeColorOutput(`Failed to get package list for ${packageName} (exit code: ${result.exitCode})`, 'red');
            writeColorOutput(`Output: ${result.stderr}`, 'red');
            return null;
        }
        
        const output = result.stdout.split('\n');
        writeColorOutput(`Conan list output length: ${output.length} lines`, 'gray');
        return parseConanListOutput(output, packageName);
    }
    catch (error) {
        writeColorOutput(`Error executing conan list for ${packageName}: ${error.message}`, 'red');
        return null;
    }
}

// Function to parse conan list output and extract revisions
function parseConanListOutput(output, packageName) {
    const revisions = {};
    let currentRevision = '';
    let currentPackageHash = '';
    let inSettings = false;
    let inOptions = false;
    let inPackageSection = false;
    
    writeColorOutput(`Starting to parse ${output.length} lines of output`, 'gray');
    
    for (const originalLine of output) {
        const line = originalLine.trim();
        
        // Skip empty lines
        if (!line) continue;
        
        // Detect main revision hash (32 character hex) with timestamp
        const revisionMatch = line.match(/^([a-f0-9]{32})\s+\((.+)\)$/);
        if (revisionMatch) {
            const potentialRevision = revisionMatch[1];
            const timestamp = revisionMatch[2];
            
            // Check indentation to determine if this is a main revision or sub-revision
            const indentLevel = originalLine.length - originalLine.trimStart().length;
            
            if (indentLevel <= 8) { // Main revision (low indent)
                currentRevision = potentialRevision;
                revisions[currentRevision] = {
                    timestamp: `${currentRevision} (${timestamp})`,
                    packages: {},
                    packageName: packageName
                };
                writeColorOutput(`  Found main revision: ${currentRevision}`, 'cyan');
                inSettings = false;
                inOptions = false;
                currentPackageHash = '';
                inPackageSection = false;
            }
            continue;
        }
        
        // Detect package hash (40 character hex)
        if (line.match(/^[a-f0-9]{40}$/) && currentRevision) {
            currentPackageHash = line;
            // Initialize package if not exists
            if (!revisions[currentRevision].packages[currentPackageHash]) {
                revisions[currentRevision].packages[currentPackageHash] = {
                    settings: {},
                    options: {}
                };
            }
            writeColorOutput(`  Found package: ${currentPackageHash}`, 'gray');
            inSettings = false;
            inOptions = false;
            inPackageSection = true;
            continue;
        }
        
        // Detect when we enter packages section
        if (line === 'packages' && currentRevision) {
            inPackageSection = true;
            continue;
        }
        
        // Detect settings section
        if (line === 'settings' && currentRevision && inPackageSection) {
            inSettings = true;
            inOptions = false;
            writeColorOutput(`  Entering settings section for revision ${currentRevision}`, 'yellow');
            continue;
        }
        
        // Detect options section
        if (line === 'options' && currentRevision && inPackageSection) {
            inOptions = true;
            inSettings = false;
            writeColorOutput(`  Entering options section for revision ${currentRevision}`, 'yellow');
            continue;
        }
        
        // Parse setting or option lines (key: value format)
        const keyValueMatch = line.match(/^(\w+(?:\.\w+)*): (.+)$/);
        if (keyValueMatch && currentRevision && inPackageSection) {
            const key = keyValueMatch[1];
            const value = keyValueMatch[2];
            
            // Find the target package hash
            let targetPackageHash = currentPackageHash;
            if (!targetPackageHash && Object.keys(revisions[currentRevision].packages).length > 0) {
                // Get the last package hash added to this revision
                const packageHashes = Object.keys(revisions[currentRevision].packages);
                targetPackageHash = packageHashes[packageHashes.length - 1];
            }
            
            if (targetPackageHash) {
                const validSettings = ['arch', 'build_type', 'compiler', 'compiler.cppstd', 
                                     'compiler.runtime', 'compiler.runtime_type', 'compiler.version', 
                                     'compiler.libcxx', 'os'];
                
                if (inSettings && validSettings.includes(key)) {
                    revisions[currentRevision].packages[targetPackageHash].settings[key] = value;
                    writeColorOutput(`  Parsed setting: ${key} = ${value} for package ${targetPackageHash}`, 'gray');
                } else if (inOptions && key === 'shared') {
                    revisions[currentRevision].packages[targetPackageHash].options[key] = value;
                    writeColorOutput(`  Parsed option: ${key} = ${value} for package ${targetPackageHash}`, 'gray');
                }
            }
        }
        
        // Reset package section when encountering main revision
        if (revisionMatch && originalLine.length - originalLine.trimStart().length <= 8) {
            inPackageSection = false;
        }
    }
    
    writeColorOutput(`Finished parsing. Found ${Object.keys(revisions).length} revisions.`, 'gray');
    return revisions;
}

// Function to select best revision for platform
function selectBestRevision(revisions, targetOS, packageName, preferredCompiler = '') {
    writeColorOutput(`Select-BestRevision TargetOS: ${targetOS}`, 'green');
    writeColorOutput(`Select-BestRevision PackageName: ${packageName}`, 'green');
    writeColorOutput(`Select-BestRevision PreferredCompiler: ${preferredCompiler}`, 'green');
    
    const candidates = [];
    
    for (const revisionHash of Object.keys(revisions)) {
        const revision = revisions[revisionHash];
        for (const packageHash of Object.keys(revision.packages)) {
            const pkg = revision.packages[packageHash];
            const settings = pkg.settings;
            
            if (settings.os === targetOS &&
                settings.arch === 'x86_64' &&
                settings.build_type === 'Release' &&
                pkg.options.shared === 'True') {
                
                let score = 0;
                
                // Prefer specific compiler if specified
                if (preferredCompiler && settings.compiler === preferredCompiler) {
                    score += 10;
                }
                
                // Prefer newer timestamps (rough heuristic based on revision order)
                score += parseInt(revisionHash.slice(-8), 16) % 100;
                
                candidates.push({
                    revision: revisionHash,
                    package: packageHash,
                    settings: settings,
                    timestamp: revision.timestamp,
                    packageName: packageName,
                    score: score
                });
            }
        }
    }
    
    if (candidates.length === 0) {
        writeColorOutput(`No suitable revision found for ${packageName} on ${targetOS}`, 'red');
        return null;
    }
    
    // Sort by score (descending) and return the best match
    const best = candidates.sort((a, b) => b.score - a.score)[0];
    
    writeColorOutput(`Selected revision for ${packageName} on ${targetOS}: ${best.revision}`, 'green');
    writeColorOutput(`  Compiler: ${best.settings.compiler} ${best.settings['compiler.version']}`, 'white');
    writeColorOutput(`  Timestamp: ${best.timestamp}`, 'white');
    
    return best;
}

// Function to find and copy native libraries
function copyNativeLibs(sourcePath, destPath, extensions) {
    const copiedFiles = [];
    
    // Check if there's a cache path file
    const cachePathFile = path.join(sourcePath, 'cache_path.txt');
    let searchPaths = [];
    
    if (fs.existsSync(cachePathFile)) {
        const cachePath = fs.readFileSync(cachePathFile, 'utf8').trim();
        writeColorOutput(`Found cache path: ${cachePath}`, 'cyan');
        
        // Add common subdirectories where binaries are typically found
        searchPaths.push(cachePath);
        searchPaths.push(path.join(cachePath, 'bin'));
        searchPaths.push(path.join(cachePath, 'lib'));
        searchPaths.push(path.join(cachePath, 'libs'));
    } else {
        // Fallback to original behavior
        searchPaths.push(sourcePath);
    }
    
    for (const searchPath of searchPaths) {
        if (!fs.existsSync(searchPath)) {
            writeColorOutput(`Search path does not exist: ${searchPath}`, 'gray');
            continue;
        }
        
        writeColorOutput(`Searching for libraries in: ${searchPath}`, 'yellow');
        
        try {
            const files = fs.readdirSync(searchPath);
            for (const file of files) {
                const filePath = path.join(searchPath, file);
                const stat = fs.statSync(filePath);
                
                if (stat.isFile()) {
                    for (const ext of extensions) {
                        if (file.endsWith(ext) || (ext.includes('*') && file.includes(ext.replace('*', '')))) {
                            const destFile = path.join(destPath, file);
                            try {
                                fs.copyFileSync(filePath, destFile);
                                copiedFiles.push(file);
                                writeColorOutput(`  Copied: ${file} from ${filePath}`, 'cyan');
                            } catch (error) {
                                writeColorOutput(`  Failed to copy: ${file} - ${error.message}`, 'red');
                            }
                        }
                    }
                }
            }
        } catch (error) {
            writeColorOutput(`Error reading directory ${searchPath}: ${error.message}`, 'red');
        }
    }
    
    return copiedFiles;
}

// Function to install package with specific settings
async function installConanPackage(packageName, remoteName, revision, settings, installDir, packageHash = '') {
    // Create conanfile.txt
    const conanfilePath = path.join(installDir, 'conanfile.txt');
    const conanfileContent = `[requires]
${packageName}#${revision}

[generators]
CMakeDeps
CMakeToolchain

[options]
*:shared=True
`;
    
    // Write conanfile.txt
    fs.writeFileSync(conanfilePath, conanfileContent, 'utf8');
    writeColorOutput(`Created conanfile.txt at: ${conanfilePath}`, 'cyan');
    writeColorOutput('Content:', 'gray');
    writeColorOutput(conanfileContent, 'gray');
    
    // Build settings arguments
    const settingsArgs = [];
    for (const [key, value] of Object.entries(settings)) {
        settingsArgs.push('-s', `${key}=${value}`);
    }
    
    // Build conan install command
    const conanArgs = [
        'install',
        '.',
        '--build=missing',
        `--remote=${remoteName}`,
        ...settingsArgs
    ];
    
    writeColorOutput(`Installing package with revision ${revision}...`, 'yellow');
    writeColorOutput(`Command: conan ${conanArgs.join(' ')}`, 'gray');
    
    try {
        const result = await executeCommand('conan', conanArgs, { cwd: installDir });
        
        if (result.exitCode === 0) {
            writeColorOutput('Successfully installed package', 'green');
            
            // If we have the package hash, get the cache path directly
            if (packageHash) {
                const packageRef = `${packageName}#${revision}:${packageHash}`;
                writeColorOutput(`Getting cache path for: ${packageRef}`, 'yellow');
                
                try {
                    const cacheResult = await executeCommand('conan', ['cache', 'path', packageRef]);
                    
                    if (cacheResult.exitCode === 0 && cacheResult.stdout.trim()) {
                        const cachePath = cacheResult.stdout.trim();
                        writeColorOutput(`Package cache path: ${cachePath}`, 'cyan');
                        
                        // Store the cache path for later use by copyNativeLibs
                        fs.writeFileSync(path.join(installDir, 'cache_path.txt'), cachePath);
                        
                        return true;
                    } else {
                        writeColorOutput(`Could not get cache path for ${packageRef}`, 'yellow');
                    }
                } catch (error) {
                    writeColorOutput(`Error getting cache path: ${error.message}`, 'red');
                }
            }
            
            return true;
        } else {
            writeColorOutput(`Failed to install package (exit code: ${result.exitCode})`, 'red');
            writeColorOutput(`Error: ${result.stderr}`, 'red');
            return false;
        }
    } catch (error) {
        writeColorOutput(`Error executing conan install: ${error.message}`, 'red');
        return false;
    }
}

// Main script execution
async function main() {
    writeColorOutput('=== Multi-Package Native Libraries Extractor ===', 'magenta');
    writeColorOutput(`Packages: ${packageNames.join(', ')}`, 'white');
    writeColorOutput(`Remote: ${remote}`, 'white');
    writeColorOutput('');
    
    // Create output directories
    const windowsNativeDir = path.join('runtimes', 'win-x64');
    const linuxNativeDir = path.join('runtimes', 'linux-x64');
    const tempDir = path.join(os.tmpdir(), 'conan-extract');
    
    ensureDirectory(windowsNativeDir);
    ensureDirectory(linuxNativeDir);
    ensureDirectory(tempDir);
    
    // Process each package
    const allWindowsRevisions = [];
    const allLinuxRevisions = [];
    let totalWindowsFiles = 0;
    let totalLinuxFiles = 0;
    
    try {
        for (const packageName of packageNames) {
            writeColorOutput(`=== Processing Package: ${packageName} ===`, 'blue');
            
            // Get available revisions from Conan
            const allRevisions = await getPackageRevisions(packageName, remote);
            
            if (!allRevisions) {
                writeColorOutput(`Failed to get revisions for ${packageName}. Skipping...`, 'red');
                continue;
            }
            
            writeColorOutput(`Found ${Object.keys(allRevisions).length} revision(s) for ${packageName}`, 'green');
            
            // Select best revisions for each platform
            const windowsMatch = selectBestRevision(allRevisions, 'Windows', packageName, 'msvc');
            const linuxMatch = selectBestRevision(allRevisions, 'Linux', packageName, 'gcc');
            
            if (windowsMatch) {
                allWindowsRevisions.push(windowsMatch);
            }
            if (linuxMatch) {
                allLinuxRevisions.push(linuxMatch);
            }
            
            writeColorOutput('');
        }
        
        // Install Windows packages
        if (allWindowsRevisions.length > 0) {
            writeColorOutput('=== Installing Windows Packages ===', 'blue');
            for (const revision of allWindowsRevisions) {
                writeColorOutput(`Installing ${revision.packageName} (Windows)...`, 'yellow');
                
                const windowsSettings = {
                    'arch': 'x86_64',
                    'build_type': 'Release',
                    'compiler': 'msvc',
                    'compiler.version': '194',
                    'compiler.cppstd': '14',
                    'compiler.runtime': 'dynamic',
                    'compiler.runtime_type': 'Release',
                    'os': 'Windows'
                };
                
                const windowsInstallDir = path.join(tempDir, 'windows', revision.packageName.replace('/', '_'));
                ensureDirectory(windowsInstallDir);
                
                const windowsSuccess = await installConanPackage(
                    revision.packageName, 
                    remote, 
                    revision.revision, 
                    windowsSettings, 
                    windowsInstallDir, 
                    revision.package
                );
                
                if (windowsSuccess) {
                    writeColorOutput(`Extracting Windows libraries for ${revision.packageName}...`, 'yellow');
                    const windowsLibs = copyNativeLibs(windowsInstallDir, windowsNativeDir, ['.dll', '.pdb', '.lib']);
                    totalWindowsFiles += windowsLibs.length;
                    writeColorOutput(`Extracted ${windowsLibs.length} files for ${revision.packageName}`, 'green');
                }
            }
        }
        
        writeColorOutput('');
        
        // Install Linux packages
        if (allLinuxRevisions.length > 0) {
            writeColorOutput('=== Installing Linux Packages ===', 'blue');
            for (const revision of allLinuxRevisions) {
                writeColorOutput(`Installing ${revision.packageName} (Linux)...`, 'yellow');
                
                const linuxSettings = {
                    'arch': 'x86_64',
                    'build_type': 'Release',
                    'compiler': 'gcc',
                    'compiler.version': '9',
                    'compiler.cppstd': 'gnu14',
                    'compiler.libcxx': 'libstdc++11',
                    'os': 'Linux'
                };
                
                const linuxInstallDir = path.join(tempDir, 'linux', revision.packageName.replace('/', '_'));
                ensureDirectory(linuxInstallDir);
                
                const linuxSuccess = await installConanPackage(
                    revision.packageName, 
                    remote, 
                    revision.revision, 
                    linuxSettings, 
                    linuxInstallDir, 
                    revision.package
                );
                
                if (linuxSuccess) {
                    writeColorOutput(`Extracting Linux libraries for ${revision.packageName}...`, 'yellow');
                    const linuxLibs = copyNativeLibs(linuxInstallDir, linuxNativeDir, ['.so', '.so.*', '.a']);
                    totalLinuxFiles += linuxLibs.length;
                    writeColorOutput(`Extracted ${linuxLibs.length} files for ${revision.packageName}`, 'green');
                }
            }
        }
        
        writeColorOutput('');
        writeColorOutput('=== Summary ===', 'magenta');
        
        if (allWindowsRevisions.length > 0) {
            writeColorOutput(`✓ Windows packages processed: ${allWindowsRevisions.length}`, 'green');
            writeColorOutput(`✓ Total Windows libraries extracted: ${totalWindowsFiles} files`, 'green');
            writeColorOutput(`✓ Windows libraries location: ${windowsNativeDir}`, 'green');
        } else {
            writeColorOutput('✗ No Windows packages processed', 'red');
        }
        
        if (allLinuxRevisions.length > 0) {
            writeColorOutput(`✓ Linux packages processed: ${allLinuxRevisions.length}`, 'green');
            writeColorOutput(`✓ Total Linux libraries extracted: ${totalLinuxFiles} files`, 'green');
            writeColorOutput(`✓ Linux libraries location: ${linuxNativeDir}`, 'green');
        } else {
            writeColorOutput('✗ No Linux packages processed', 'red');
        }
        
        // List packages processed
        if (allWindowsRevisions.length > 0 || allLinuxRevisions.length > 0) {
            writeColorOutput('\nPackages processed:', 'cyan');
            const processedPackages = [];
            processedPackages.push(...allWindowsRevisions.map(r => r.packageName));
            processedPackages.push(...allLinuxRevisions.map(r => r.packageName));
            const uniquePackages = [...new Set(processedPackages)].sort();
            
            for (const pkg of uniquePackages) {
                const winRevision = allWindowsRevisions.find(r => r.packageName === pkg)?.revision;
                const linRevision = allLinuxRevisions.find(r => r.packageName === pkg)?.revision;
                
                writeColorOutput(`  ${pkg}`, 'white');
                if (winRevision) writeColorOutput(`    Windows: ${winRevision}`, 'gray');
                if (linRevision) writeColorOutput(`    Linux: ${linRevision}`, 'gray');
            }
        }
        
        // List extracted files
        if (fs.existsSync(windowsNativeDir)) {
            const winFiles = fs.readdirSync(windowsNativeDir).filter(f => 
                fs.statSync(path.join(windowsNativeDir, f)).isFile()
            );
            if (winFiles.length > 0) {
                writeColorOutput('\nWindows files:', 'cyan');
                winFiles.forEach(file => writeColorOutput(`  ${file}`, 'white'));
            }
        }
        
        if (fs.existsSync(linuxNativeDir)) {
            const linFiles = fs.readdirSync(linuxNativeDir).filter(f => 
                fs.statSync(path.join(linuxNativeDir, f)).isFile()
            );
            if (linFiles.length > 0) {
                writeColorOutput('\nLinux files:', 'cyan');
                linFiles.forEach(file => writeColorOutput(`  ${file}`, 'white'));
            }
        }
        
    } finally {
        // Cleanup temporary directory
        if (fs.existsSync(tempDir)) {
            try {
                fs.rmSync(tempDir, { recursive: true, force: true });
                writeColorOutput(`\nCleaned up temporary directory: ${tempDir}`, 'gray');
            } catch (error) {
                writeColorOutput(`\nWarning: Could not clean up temporary directory: ${tempDir}`, 'yellow');
            }
        }
    }
    
    writeColorOutput('\n=== Extraction Complete ===', 'magenta');
}

// Handle script execution
if (require.main === module) {
    main().catch(error => {
        writeColorOutput(`Fatal error: ${error.message}`, 'red');
        process.exit(1);
    });
}

module.exports = {
    writeColorOutput,
    ensureDirectory,
    executeCommand,
    getPackageRevisions,
    parseConanListOutput,
    selectBestRevision,
    copyNativeLibs,
    installConanPackage
};
