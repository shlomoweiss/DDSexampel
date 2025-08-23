#!/usr/bin/env pwsh
# extract-native-libs.ps1
# Script to install multiple packages for Windows and Linux platforms and extract native libraries

param(
    [string[]]$PackageNames = @("ddsmessage/1.0.0", "icdwrappercpp/1.0.0"),
    [string]$Remote = "local-conan",
    [string]$OutputDir = "native-libs"
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    # Validate color parameter
    $validColors = @("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
    if ($Color -notin $validColors) {
        $Color = "White"
    }
    
    Write-Host $Message -ForegroundColor $Color
}

# Function to ensure directory exists
function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-ColorOutput "Created directory: $Path" "Green"
    }
}

# Function to get package revisions from conan list
function Get-PackageRevisions {
    param(
        [string]$Package,
        [string]$RemoteName
    )
    
    Write-ColorOutput "Getting revisions for package: $Package" "Yellow"
    $listCommand = "conan list `"$Package#*:*#*`" -r $RemoteName"
    Write-ColorOutput "Running: $listCommand" "Gray"
    
    try {
        $output = & conan list "$Package#*:*#*" -r $RemoteName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Failed to get package list for $Package (exit code: $LASTEXITCODE)" "Red"
            Write-ColorOutput "Output: $output" "Red"
            return $null
        }
        
        Write-ColorOutput "Conan list output length: $($output.Length) lines" "Gray"
        return Parse-ConanListOutput -Output $output -PackageName $Package
    }
    catch {
        Write-ColorOutput "Error executing conan list for $Package`: $($_.Exception.Message)" "Red"
        Write-ColorOutput "Error details: $($_.Exception)" "Red"
        return $null
    }
}

# Function to parse conan list output and extract revisions
function Parse-ConanListOutput {
    param(
        [string[]]$Output,
        [string]$PackageName
    )
    
    $revisions = @{}
    $currentRevision = ""
    $currentPackageHash = ""
    $inSettings = $false
    $inOptions = $false
    $inPackageSection = $false
    
    Write-ColorOutput "Starting to parse $($Output.Length) lines of output" "Gray"
    
    foreach ($line in $Output) {
        $originalLine = $line
        $line = $line.Trim()
        
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        # Detect main revision hash (32 character hex) with timestamp - these are the main package revisions
        if ($line -match '^([a-f0-9]{32})\s+\((.+)\)$') {
            $potentialRevision = $matches[1]
            $timestamp = $matches[2]
            
            # Check indentation to determine if this is a main revision or a sub-revision
            $indentLevel = $originalLine.Length - $originalLine.TrimStart().Length
            
            if ($indentLevel -le 8) { # Main revision (low indent)
                $currentRevision = $potentialRevision
                $revisions[$currentRevision] = @{
                    'timestamp' = "$currentRevision ($timestamp)"
                    'packages' = @{}
                    'packageName' = $PackageName
                }
                Write-ColorOutput "  Found main revision: $currentRevision" "Cyan"
                $inSettings = $false
                $inOptions = $false
                $currentPackageHash = ""
                $inPackageSection = $false
            }
            # If it's a sub-revision (high indent), we ignore it for package matching
            continue
        }
        
        # Detect package hash (40 character hex)
        if ($line -match '^[a-f0-9]{40}$' -and $currentRevision) {
            $currentPackageHash = $line
            # Initialize package if not exists
            if (-not $revisions[$currentRevision].packages.ContainsKey($currentPackageHash)) {
                $revisions[$currentRevision].packages[$currentPackageHash] = @{
                    'settings' = @{}
                    'options' = @{}
                }
            }
            Write-ColorOutput "  Found package: $currentPackageHash" "Gray"
            $inSettings = $false
            $inOptions = $false
            $inPackageSection = $true
            continue
        }
        
        # Detect when we enter packages section
        if ($line -eq "packages" -and $currentRevision) {
            $inPackageSection = $true
            continue
        }
        
        # Detect settings section (must be in a package section)
        if ($line -eq "settings" -and $currentRevision -and $inPackageSection) {
            $inSettings = $true
            $inOptions = $false
            Write-ColorOutput "  Entering settings section for revision $currentRevision" "Yellow"
            continue
        }
        
        # Detect options section (must be in a package section)
        if ($line -eq "options" -and $currentRevision -and $inPackageSection) {
            $inOptions = $true
            $inSettings = $false
            Write-ColorOutput "  Entering options section for revision $currentRevision" "Yellow"
            continue
        }
        
        # Parse setting or option lines (key: value format)
        if ($line -match '^(\w+(?:\.\w+)*): (.+)$' -and $currentRevision -and $inPackageSection) {
            $key = $matches[1]
            $value = $matches[2]
            
            # We need to find the most recent package hash for this revision
            $targetPackageHash = $currentPackageHash
            if (-not $targetPackageHash -and $revisions[$currentRevision].packages.Count -gt 0) {
                # Get the last package hash added to this revision
                $targetPackageHash = $revisions[$currentRevision].packages.Keys | Select-Object -Last 1
            }
            
            if ($targetPackageHash) {
                if ($inSettings -and $key -in @('arch', 'build_type', 'compiler', 'compiler.cppstd', 'compiler.runtime', 'compiler.runtime_type', 'compiler.version', 'compiler.libcxx', 'os')) {
                    $revisions[$currentRevision].packages[$targetPackageHash].settings[$key] = $value
                    Write-ColorOutput "  Parsed setting: $key = $value for package $targetPackageHash" "Gray"
                } elseif ($inOptions -and $key -eq 'shared') {
                    $revisions[$currentRevision].packages[$targetPackageHash].options[$key] = $value
                    Write-ColorOutput "  Parsed option: $key = $value for package $targetPackageHash" "Gray"
                }
            }
        }
        
        # Reset package section when we encounter certain structural elements
        if ($line -eq "revisions" -or ($line -match '^[a-f0-9]{32}\s+\(' -and $originalLine.Length - $originalLine.TrimStart().Length -le 8)) {
            # Don't reset inPackageSection when encountering "revisions" - we're still in a package context
            # Only reset when we encounter a main revision (low indent level)
            if ($line -match '^[a-f0-9]{32}\s+\(' -and $originalLine.Length - $originalLine.TrimStart().Length -le 8) {
                $inPackageSection = $false
            }
        }
    }
    
    Write-ColorOutput "Finished parsing. Found $($revisions.Count) revisions." "Gray"
    return $revisions
}

# Function to select best revision for platform
function Select-BestRevision {
    param(
        [hashtable]$Revisions,
        [string]$TargetOS,
        [string]$PackageName,
        [string]$PreferredCompiler = ""
    )

    Write-ColorOutput "Select-BestRevision TargetOS: $TargetOS" "Green"
    Write-ColorOutput "Select-BestRevision PackageName: $PackageName" "Green"
    Write-ColorOutput "Select-BestRevision PreferredCompiler: $PreferredCompiler" "Green"
    $candidates = @()
    
    foreach ($revisionHash in $Revisions.Keys) {
        $revision = $Revisions[$revisionHash]
        foreach ($packageHash in $revision.packages.Keys) {
            $package = $revision.packages[$packageHash]
            $settings = $package.settings 
            
            if ($settings.os -eq $TargetOS -and 
                $settings.arch -eq 'x86_64' -and 
                $settings.build_type -eq 'Release' -and
                $package.options.shared -eq 'True') {
                
                $score = 0
                
                # Prefer specific compiler if specified
                if ($PreferredCompiler -and $settings.compiler -eq $PreferredCompiler) {
                    $score += 10
                }
                
                # Prefer newer timestamps (rough heuristic based on revision order)
                $score += $revisionHash.GetHashCode() % 100
                
                $candidates += @{
                    'revision' = $revisionHash
                    'package' = $packageHash
                    'settings' = $settings
                    'timestamp' = $revision.timestamp
                    'packageName' = $PackageName
                    'score' = $score
                }
            }
        }
    }
    
    if ($candidates.Count -eq 0) {
        Write-ColorOutput "No suitable revision found for $PackageName on $TargetOS" "Red"
        return $null
    }
    
    # Sort by score (descending) and return the best match
    $best = $candidates | Sort-Object score -Descending | Select-Object -First 1
    
    Write-ColorOutput "Selected revision for $PackageName on $TargetOS`: $($best.revision)" "Green"
    Write-ColorOutput "  Compiler: $($best.settings.compiler) $($best.settings.'compiler.version')" "White"
    Write-ColorOutput "  Timestamp: $($best.timestamp)" "White"
    
    return $best
}

# Function to find and copy native libraries
function Copy-NativeLibs {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [string[]]$Extensions
    )
    
    $copiedFiles = @()
    
    # Check if there's a cache path file indicating where the actual binaries are
    $cachePathFile = Join-Path $SourcePath "cache_path.txt"
    $searchPaths = @()
    
    if (Test-Path $cachePathFile) {
        $cachePath = (Get-Content $cachePathFile).Trim()
        Write-ColorOutput "Found cache path: $cachePath" "Cyan"
        
        # Add common subdirectories where binaries are typically found
        $searchPaths += $cachePath
        $searchPaths += Join-Path $cachePath "bin"
        $searchPaths += Join-Path $cachePath "lib"
        $searchPaths += Join-Path $cachePath "libs"
    } else {
        # Fallback to original behavior - search the source path
        $searchPaths += $SourcePath
    }
    
    foreach ($searchPath in $searchPaths) {
        if (-not (Test-Path $searchPath)) {
            Write-ColorOutput "Search path does not exist: $searchPath" "Gray"
            continue
        }
        
        Write-ColorOutput "Searching for libraries in: $searchPath" "Yellow"
        
        foreach ($ext in $Extensions) {
            $files = Get-ChildItem -Path $searchPath -Filter "*$ext" -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $destFile = Join-Path $DestPath $file.Name
                try {
                    Copy-Item $file.FullName $destFile -Force
                    $copiedFiles += $file.Name
                    Write-ColorOutput "  Copied: $($file.Name) from $($file.FullName)" "Cyan"
                }
                catch {
                    Write-ColorOutput "  Failed to copy: $($file.Name) - $($_.Exception.Message)" "Red"
                }
            }
        }
    }
    
    return $copiedFiles
}

# Function to install package with specific settings
function Install-ConanPackage {
    param(
        [string]$Package,
        [string]$RemoteName,
        [string]$Revision,
        [hashtable]$Settings,
        [string]$InstallDir,
        [string]$PackageHash = ""
    )
    
    # Create conanfile.txt with the package and revision
    $conanfilePath = Join-Path $InstallDir "conanfile.txt"
    $conanfileContent = @"
[requires]
$Package#$Revision

[generators]
CMakeDeps
CMakeToolchain

[options]
*:shared=True
"@
    
    # Write conanfile.txt
    Set-Content -Path $conanfilePath -Value $conanfileContent -Encoding UTF8
    Write-ColorOutput "Created conanfile.txt at: $conanfilePath" "Cyan"
    Write-ColorOutput "Content:" "Gray"
    Write-ColorOutput $conanfileContent "Gray"
    
    # Build settings string
    $settingsArgs = @()
    foreach ($key in $Settings.Keys) {
        $settingsArgs += "-s"
        $settingsArgs += "$key=$($Settings[$key])"
    }
    
    # Build conan install command
    $conanArgs = @(
        "install",
        ".",
        "--build=missing",
        "--remote=$RemoteName"
    ) + $settingsArgs
    
    Write-ColorOutput "Installing package with revision $Revision..." "Yellow"
    Write-ColorOutput "Command: conan $($conanArgs -join ' ')" "Gray"
    
    # Change to install directory to run conan install
    $originalLocation = Get-Location
    try {
        Set-Location $InstallDir
        $process = Start-Process -FilePath "conan" -ArgumentList $conanArgs -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "Successfully installed package" "Green"
            
            # If we have the package hash, get the cache path directly
            if ($PackageHash) {
                $packageRef = "${Package}#${Revision}:${PackageHash}"
                Write-ColorOutput "Getting cache path for: $packageRef" "Yellow"
                
                try {
                    $cachePathArgs = @("cache", "path", $packageRef)
                    $cacheProcess = Start-Process -FilePath "conan" -ArgumentList $cachePathArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$InstallDir\cache_path.txt" 2>$null
                    
                    if ($cacheProcess.ExitCode -eq 0 -and (Test-Path "$InstallDir\cache_path.txt")) {
                        $cachePath = (Get-Content "$InstallDir\cache_path.txt").Trim()
                        Write-ColorOutput "Package cache path: $cachePath" "Cyan"
                        
                        # Store the cache path in the install directory for later use by Copy-NativeLibs
                        Set-Content -Path (Join-Path $InstallDir "cache_path.txt") -Value $cachePath
                        
                        return $true
                    } else {
                        Write-ColorOutput "Could not get cache path for $packageRef" "Yellow"
                    }
                }
                catch {
                    Write-ColorOutput "Error getting cache path: $($_.Exception.Message)" "Red"
                }
            }
            
            return $true
        } else {
            Write-ColorOutput "Failed to install package (exit code: $($process.ExitCode))" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Error executing conan install: $($_.Exception.Message)" "Red"
        return $false
    }
    finally {
        Set-Location $originalLocation
    }
}

# Main script execution
Write-ColorOutput "=== Multi-Package Native Libraries Extractor ===" "Magenta"
Write-ColorOutput "Packages: $($PackageNames -join ', ')" "White"
Write-ColorOutput "Remote: $Remote" "White"
Write-ColorOutput ""

# Create output directories
$windowsNativeDir = Join-Path "runtimes" "win-x64"
$linuxNativeDir = Join-Path "runtimes" "linux-x64"
$tempDir = Join-Path $env:TEMP "conan-extract"

Ensure-Directory $windowsNativeDir
Ensure-Directory $linuxNativeDir
Ensure-Directory $tempDir

# Process each package
$allWindowsRevisions = @()
$allLinuxRevisions = @()
$totalWindowsFiles = 0
$totalLinuxFiles = 0

try {
    foreach ($packageName in $PackageNames) {
        Write-ColorOutput "=== Processing Package: $packageName ===" "Blue"
        
        # Get available revisions from Conan
        $allRevisions = Get-PackageRevisions -Package $packageName -RemoteName $Remote
        
        if (-not $allRevisions) {
            Write-ColorOutput "Failed to get revisions for $packageName. Skipping..." "Red"
            continue
        }
        
        Write-ColorOutput "Found $($allRevisions.Count) revision(s) for $packageName" "Green"
        
        # Select best revisions for each platform
        $windowsMatch = Select-BestRevision -Revisions $allRevisions -TargetOS "Windows" -PackageName $packageName -PreferredCompiler "msvc"
        $linuxMatch = Select-BestRevision -Revisions $allRevisions -TargetOS "Linux" -PackageName $packageName -PreferredCompiler "gcc"
        
        if ($windowsMatch) {
            $allWindowsRevisions += $windowsMatch
        }
        if ($linuxMatch) {
            $allLinuxRevisions += $linuxMatch
        }
        
        Write-ColorOutput ""
    }
    
    # Install Windows packages
    if ($allWindowsRevisions.Count -gt 0) {
        Write-ColorOutput "=== Installing Windows Packages ===" "Blue"
        foreach ($revision in $allWindowsRevisions) {
            Write-ColorOutput "Installing $($revision.packageName) (Windows)..." "Yellow"
            
            $windowsSettings = @{
                "arch" = "x86_64"
                "build_type" = "Release"
                "compiler" = "msvc"
                "compiler.version" = "194"
                "compiler.cppstd" = "14"
                "compiler.runtime" = "dynamic"
                "compiler.runtime_type" = "Release"
                "os" = "Windows"
            }
            
            $windowsInstallDir = Join-Path $tempDir "windows/$($revision.packageName.Replace('/', '_'))"
            Ensure-Directory $windowsInstallDir
            
            $windowsSuccess = Install-ConanPackage -Package $revision.packageName -RemoteName $Remote -Revision $revision.revision -Settings $windowsSettings -InstallDir $windowsInstallDir -PackageHash $revision.package
            
            if ($windowsSuccess) {
                Write-ColorOutput "Extracting Windows libraries for $($revision.packageName)..." "Yellow"
                $windowsLibs = Copy-NativeLibs -SourcePath $windowsInstallDir -DestPath $windowsNativeDir -Extensions @(".dll", ".pdb", ".lib")
                $totalWindowsFiles += $windowsLibs.Count
                Write-ColorOutput "Extracted $($windowsLibs.Count) files for $($revision.packageName)" "Green"
            }
        }
    }
    
    Write-ColorOutput ""
    
    # Install Linux packages
    if ($allLinuxRevisions.Count -gt 0) {
        Write-ColorOutput "=== Installing Linux Packages ===" "Blue"
        foreach ($revision in $allLinuxRevisions) {
            Write-ColorOutput "Installing $($revision.packageName) (Linux)..." "Yellow"
            
            $linuxSettings = @{
                "arch" = "x86_64"
                "build_type" = "Release"
                "compiler" = "gcc"
                "compiler.version" = "9"
                "compiler.cppstd" = "gnu14"
                "compiler.libcxx" = "libstdc++11"
                "os" = "Linux"
            }
            
            $linuxInstallDir = Join-Path $tempDir "linux/$($revision.packageName.Replace('/', '_'))"
            Ensure-Directory $linuxInstallDir
            
            $linuxSuccess = Install-ConanPackage -Package $revision.packageName -RemoteName $Remote -Revision $revision.revision -Settings $linuxSettings -InstallDir $linuxInstallDir -PackageHash $revision.package
            
            if ($linuxSuccess) {
                Write-ColorOutput "Extracting Linux libraries for $($revision.packageName)..." "Yellow"
                $linuxLibs = Copy-NativeLibs -SourcePath $linuxInstallDir -DestPath $linuxNativeDir -Extensions @(".so", ".so.*", ".a")
                $totalLinuxFiles += $linuxLibs.Count
                Write-ColorOutput "Extracted $($linuxLibs.Count) files for $($revision.packageName)" "Green"
            }
        }
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "=== Summary ===" "Magenta"
    
    if ($allWindowsRevisions.Count -gt 0) {
        Write-ColorOutput "v Windows packages processed: $($allWindowsRevisions.Count)" "Green"
        Write-ColorOutput "v Total Windows libraries extracted: $totalWindowsFiles files" "Green"
        Write-ColorOutput "v Windows libraries location: $windowsNativeDir" "Green"
    } else {
        Write-ColorOutput "x No Windows packages processed" "Red"
    }
    
    if ($allLinuxRevisions.Count -gt 0) {
        Write-ColorOutput "v Linux packages processed: $($allLinuxRevisions.Count)" "Green"
        Write-ColorOutput "v Total Linux libraries extracted: $totalLinuxFiles files" "Green"
        Write-ColorOutput "v Linux libraries location: $linuxNativeDir" "Green"
    } else {
        Write-ColorOutput "x No Linux packages processed" "Red"
    }
    
    # List packages processed
    if ($allWindowsRevisions.Count -gt 0 -or $allLinuxRevisions.Count -gt 0) {
        Write-ColorOutput "`nPackages processed:" "Cyan"
        $processedPackages = @()
        $processedPackages += $allWindowsRevisions | ForEach-Object { $_.packageName }
        $processedPackages += $allLinuxRevisions | ForEach-Object { $_.packageName }
        $uniquePackages = $processedPackages | Sort-Object -Unique
        
        foreach ($pkg in $uniquePackages) {
            $winRevision = ($allWindowsRevisions | Where-Object { $_.packageName -eq $pkg }).revision
            $linRevision = ($allLinuxRevisions | Where-Object { $_.packageName -eq $pkg }).revision
            
            Write-ColorOutput "  $pkg" "White"
            if ($winRevision) { Write-ColorOutput "    Windows: $winRevision" "Gray" }
            if ($linRevision) { Write-ColorOutput "    Linux: $linRevision" "Gray" }
        }
    }
    
    # List extracted files
    if (Test-Path $windowsNativeDir) {
        $winFiles = Get-ChildItem $windowsNativeDir -File
        if ($winFiles.Count -gt 0) {
            Write-ColorOutput "`nWindows files:" "Cyan"
            $winFiles | ForEach-Object { Write-ColorOutput "  $($_.Name)" "White" }
        }
    }
    
    if (Test-Path $linuxNativeDir) {
        $linFiles = Get-ChildItem $linuxNativeDir -File  
        if ($linFiles.Count -gt 0) {
            Write-ColorOutput "`nLinux files:" "Cyan"
            $linFiles | ForEach-Object { Write-ColorOutput "  $($_.Name)" "White" }
        }
    }
}
finally {
    # Cleanup temporary directory
    if (Test-Path $tempDir) {
        try {
            Remove-Item $tempDir -Recurse -Force
            Write-ColorOutput "`nCleaned up temporary directory: $tempDir" "Gray"
        }
        catch {
            Write-ColorOutput "`nWarning: Could not clean up temporary directory: $tempDir" "Yellow"
        }
    }
}

Write-ColorOutput "`n=== Extraction Complete ===" "Magenta"