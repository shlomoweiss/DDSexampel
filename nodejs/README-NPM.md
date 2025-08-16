# DDS Node.js Addon - Cross-Platform NPM Package

A cross-platform Node.js addon for DDS (Data Distribution Service) messaging using FastDDS.

## 🚀 Features

- **Cross-platform support** (Windows & Linux)
- **Self-contained npm package** (includes ICD library source)
- **Real-time publish/subscribe messaging**
- **Built with N-API** for Node.js compatibility
- **Domain isolation** and configuration support
- **Automatic dependency checking**

## 📋 Prerequisites

### Windows
- Visual Studio Build Tools 2019 or later
- FastDDS 3.2.2 installed at `C:/fastdds 3.2.2/` 
- Or set `FASTDDS_ROOT` environment variable to your FastDDS installation

### Linux  
- GCC/G++ compiler
- FastDDS development libraries:
```bash
# Ubuntu/Debian
sudo apt install libfastdds-dev libfastcdr-dev

# Or build from source
# See: https://fast-dds.docs.eprosima.com/
```

## 📦 Installation

```bash
npm install dds-addon
```

The package will automatically:
1. ✅ Check for FastDDS dependencies
2. 🔨 Build the ICD library for your platform  
3. ⚙️ Compile the Node.js addon

## 🎯 Usage

### Basic Publisher/Subscriber

```javascript
const dds = require('dds-addon');

// Initialize DDS
dds.init('TestTopic');

// Publisher
dds.write(1, 'Hello DDS!');

// Subscriber  
const message = dds.takeMessage();
if (message) {
    console.log('Received:', message);
}

// Cleanup
dds.shutdown();
```

### Domain Configuration

```javascript
// Use specific domain ID
dds.initWithDomain('MyTopic', 42);

// Use environment variable
process.env.DDS_DOMAIN_ID = '10';
dds.init('MyTopic'); // Will use domain 10
```

### Struct-based Messaging

```javascript
// Create HelloWorld struct
const helloWorld = {
    index: 123,
    message: 'Hello from struct!'
};

// Publish struct
dds.writeStruct(helloWorld);

// Subscribe to struct
const receivedStruct = {};
if (dds.takeStruct(receivedStruct)) {
    console.log('Struct received:', receivedStruct);
}
```

## 🧪 Examples

Run the included examples:

```bash
# Basic functionality test
node examples/test.js

# Domain isolation test  
node examples/test-domain.js

# Publisher (in one terminal)
node examples/publisher.js TestTopic

# Subscriber (in another terminal)
node examples/subscriber.js TestTopic
```

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DDS_DOMAIN_ID` | DDS domain ID to use | 0 |
| `FASTDDS_ROOT` | FastDDS installation path (Windows) | `C:/fastdds 3.2.2` |

## 📖 API Reference

### Initialization
- `init(topicName)` - Initialize with default domain (0)
- `initWithDomain(topicName, domainId)` - Initialize with specific domain
- `shutdown()` - Clean up all DDS entities

### Publishing
- `write(index, message)` - Publish simple message
- `writeStruct(helloWorldStruct)` - Publish complete struct

### Subscribing  
- `take()` - Take message (returns array: [index, message])
- `takeMessage()` - Take message (returns string or null)
- `takeStruct(outputStruct)` - Take struct (fills output object)

## 🛠️ Building from Source

```bash
# Clone repository
git clone <your-repo-url>
cd nodejs

# Install dependencies
npm install

# Build
npm run build

# Test
npm test
```

## 🚨 Troubleshooting

### Windows Issues
- Ensure Visual Studio Build Tools are installed
- Check FastDDS installation path
- Set `FASTDDS_ROOT` environment variable if needed

### Linux Issues
- Install FastDDS development packages:
  ```bash
  sudo apt install libfastdds-dev libfastcdr-dev
  ```
- Check library paths with `ldconfig -p | grep fastdds`

### Build Issues
- Clean build: `npm run clean && npm run build`
- Check dependency script: `node scripts/check-dependencies.js`
- Verify Node.js version >= 16.0.0

## 📄 License

MIT

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test on both Windows and Linux
5. Submit pull request

## 🎁 What Makes This Package Special

✅ **Self-contained**: No external DDS library dependencies to install separately  
✅ **Cross-platform**: Works on Windows and Linux out of the box  
✅ **npm-ready**: Install with just `npm install dds-addon`  
✅ **Flexible paths**: Automatically detects FastDDS installation  
✅ **Real-time**: Low-latency publish/subscribe messaging  
✅ **Domain isolation**: Multiple independent communication domains
