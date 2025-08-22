# ICDWrapperSharp NuGet Package

This NuGet package provides a C# wrapper for ICD DDS messaging functionality, including both managed and native dependencies.

## What's Included

- **Managed Library**: `ICDWrapperSharp.dll` - The C# wrapper classes
- **Native Library**: `ICDWrapper.dll` - The native C++ library (Windows x64)
- **Build Integration**: Automatic copying of native dependencies to output directory

## Usage

### Installation

```bash
# Using Package Manager Console in Visual Studio
Install-Package ICDWrapperSharp

# Using .NET CLI
dotnet add package ICDWrapperSharp
```

### In Your Code

```csharp
using ICDWrapperSharp;

// Use the wrapper classes
// (Add specific usage examples based on your API)
```

## Requirements

- .NET 9.0 or later
- Windows x64 platform (for native dependencies)

## Building from Source

If you need to build the package from source:

1. Build the native C++ library first:
   ```bash
   cd ICDWrapperCpp/build
   cmake ..
   cmake --build . --config Release
   ```

2. Build and package the C# wrapper:
   ```bash
   cd ICDWrapperCsharp
   .\create-nuget-package.ps1
   ```

## Package Structure

```
ICDWrapperSharp.1.0.0.nupkg
├── lib/net9.0/
│   ├── ICDWrapperSharp.dll
│   └── ICDWrapperSharp.pdb
├── runtimes/win-x64/native/
│   └── ICDWrapper.dll
├── build/
│   └── ICDWrapperSharp.props
├── src/
│   └── *.cs (source files)
└── docs/
    └── Readme.md
```

The native DLL (`ICDWrapper.dll`) will be automatically copied to your application's output directory when you build your project.

## Troubleshooting

- Ensure you're targeting Windows x64 architecture
- Make sure the native DLL is in the same directory as your executable
- Check that .NET 9.0 runtime is installed on target machines
