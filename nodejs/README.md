# DDS Node.js Addon

This is a Node.js addon that provides a JavaScript interface to the DDS (Data Distribution Service) messaging system using N-API. It wraps the DDS facade C++ library to enable publish/subscribe messaging patterns in Node.js applications.

## Prerequisites

- Node.js (version 14 or later)
- Python 3.x (for node-gyp)
- Visual Studio Build Tools (on Windows)
- FastDDS library installed
- DDS facade library compiled

## Installation

1. Navigate to the nodejs directory:
```bash
cd nodejs
```

2. Install dependencies:
```bash
npm install
```

3. Build the native addon:
```bash
npm run build
```

## API Reference

### DDSMessaging Class

The main class that provides DDS messaging functionality.

#### Constructor

```javascript
const dds = new DDSMessaging();
```

#### Methods

- `init(topicName)` - Initialize DDS with a topic name
  - **Parameters**: `topicName` (string) - The name of the DDS topic
  - **Returns**: boolean - Success status
  - **Note**: Uses `DDS_DOMAIN_ID` environment variable or defaults to domain 0

- `initWithDomain(topicName, domainId)` - Initialize DDS with explicit domain ID
  - **Parameters**: `topicName` (string), `domainId` (number, 0-232)
  - **Returns**: boolean - Success status

- `getConfig()` - Get current configuration
  - **Returns**: object with `initialized`, `domainId`, and `topicName` properties

- `writeStruct(helloWorld)` - Write a HelloWorld struct
  - **Parameters**: `helloWorld` (object) - Object with `index` (number) and `message` (string) properties
  - **Returns**: boolean - Success status

- `takeStruct()` - Take a HelloWorld struct
  - **Returns**: object|null - Object with `index` and `message` properties, or null if no data

- `write(index, message)` - Write a message with index (legacy method)
  - **Parameters**: `index` (number), `message` (string)
  - **Returns**: boolean - Success status

- `take()` - Take a message (legacy method)
  - **Returns**: object|null - Object with `index` and `message` properties, or null if no data

- `takeMessage()` - Take a message and return it directly
  - **Returns**: object|null - Object with `index` and `message` properties, or null if no data

- `shutdown()` - Shutdown DDS

## Environment Variables

The addon supports the standard DDS environment variable:

- `DDS_DOMAIN_ID` - Sets the default domain ID (0-232) when using `init()`

## Usage Examples

### Basic Publisher

```javascript
const DDSMessaging = require('./index');

const dds = new DDSMessaging();

// Method 1: Use environment variable or default domain 0
dds.init('MyTopic');

// Method 2: Explicit domain ID
// dds.initWithDomain('MyTopic', 5);

// Check configuration
console.log(dds.getConfig());

// Publish a message
const helloWorld = {
  index: 1,
  message: 'Hello from Node.js!'
};

if (dds.writeStruct(helloWorld)) {
  console.log('Message published successfully');
}

// Cleanup
dds.shutdown();
```

### Basic Subscriber

```javascript
const DDSMessaging = require('./index');

const dds = new DDSMessaging();

// Initialize (using DDS_DOMAIN_ID env var if set)
dds.init('MyTopic');

// Check for messages
const result = dds.takeStruct();
if (result) {
  console.log(`Received: ${result.index} - ${result.message}`);
}

// Cleanup
dds.shutdown();
```

### Environment Variable Usage

```bash
# PowerShell
$env:DDS_DOMAIN_ID = "10"
node examples/publisher.js MyTopic

# Command line arguments (override environment)
node examples/publisher.js MyTopic 20
node examples/subscriber.js MyTopic 20
```

## Running the Examples

**Important**: Before running any examples, you need to set up the environment to include the required DLLs in your PATH.

### Setup Environment

**Option 1: Using PowerShell (Recommended)**
```powershell
.\setup-env.ps1
```

**Option 2: Using Batch Script**
```cmd
setup-env.bat
```

**Option 3: Manual Setup (PowerShell)**
```powershell
$env:PATH += ";C:\fastdds 3.2.2\bin\x64Win64VS2019"
$env:PATH += ";C:\cpp-prj\DDSexampel\DDSmessage\build\Release"
```

### Publisher Example

Run the publisher that sends messages every 2 seconds:

**Option 1: Direct (after environment setup)**
```bash
node examples/publisher.js [topicName]
```

**Option 2: Using provided script**
```powershell
.\run-publisher.ps1
```

### Subscriber Example

Run the subscriber that listens for messages:

**Option 1: Direct (after environment setup)**
```bash
node examples/subscriber.js [topicName]
```

**Option 2: Using provided script**
```powershell
.\run-subscriber.ps1
```

### Test Example

Run a comprehensive test that demonstrates all functionality:

**After environment setup:**
```bash
node examples/test.js
```

### Running Publisher and Subscriber Together

**Method 1: Using provided scripts**

Terminal 1:
```powershell
.\run-subscriber.ps1
```

Terminal 2:
```powershell
.\run-publisher.ps1
```

**Method 2: After manual environment setup**

Terminal 1:
```powershell
# Setup environment first
$env:PATH += ";C:\fastdds 3.2.2\bin\x64Win64VS2019;C:\cpp-prj\DDSexampel\DDSmessage\build\Release"
node examples/subscriber.js
```

Terminal 2:
```powershell
# Setup environment first
$env:PATH += ";C:\fastdds 3.2.2\bin\x64Win64VS2019;C:\cpp-prj\DDSexampel\DDSmessage\build\Release"
node examples/publisher.js
```

## Build Configuration

The addon is configured through `binding.gyp` and includes:

- N-API bindings for Node.js compatibility
- Links to FastDDS and FastCDR libraries
- Includes DDS facade headers
- Windows-specific configurations

## Troubleshooting

### Build Issues

1. **Missing headers**: Ensure FastDDS and FastCDR are properly installed
2. **Library linking errors**: Check that library paths in `binding.gyp` are correct
3. **Node.js version**: Use Node.js 14 or later for N-API compatibility

### Runtime Issues

1. **DLL not found**: Ensure the DDS facade DLL is in the system PATH or same directory
2. **Initialization failures**: Check that FastDDS runtime is properly installed
3. **No messages received**: Verify that publisher and subscriber use the same topic name

## File Structure

```
nodejs/
├── binding.gyp              # Build configuration
├── package.json             # Node.js package configuration
├── index.js                # Main JavaScript wrapper
├── setup-env.bat           # Environment setup (batch)
├── setup-env.ps1           # Environment setup (PowerShell)
├── run-publisher.ps1       # Publisher runner script
├── run-subscriber.ps1      # Subscriber runner script
├── README.md               # This file
├── src/
│   └── addon.cpp           # N-API C++ addon source
└── examples/
    ├── publisher.js        # Publisher example
    ├── subscriber.js       # Subscriber example
    └── test.js            # Comprehensive test
```

## License

MIT License - See the LICENSE file for details.
