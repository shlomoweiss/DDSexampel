# DDS Domain Examples

This directory contains examples demonstrating how to use environment variables and domain IDs with the DDS Node.js addon.

## Environment Variable Support

The addon supports the standard DDS environment variable:

- `DDS_DOMAIN_ID` - Sets the default domain ID (0-232)

## Usage Examples

### Using Environment Variables

```bash
# Set domain ID via environment variable
$env:DDS_DOMAIN_ID = "5"
node examples/publisher.js MyTopic

# Or in a single command
$env:DDS_DOMAIN_ID = "10"; node examples/subscriber.js MyTopic
```

### Using Command Line Arguments

```bash
# publisher.js [topicName] [domainId]
node examples/publisher.js MyTopic 15

# subscriber.js [topicName] [domainId]
node examples/subscriber.js MyTopic 15
```

### Using JavaScript API

```javascript
const DDSMessaging = require('./index');

const dds = new DDSMessaging();

// Method 1: Use environment variable or default
dds.init('MyTopic');

// Method 2: Explicit domain ID
dds.initWithDomain('MyTopic', 25);

// Check current configuration
console.log(dds.getConfig());
```

## Domain Isolation

Different domain IDs provide network isolation. Publishers and subscribers on different domains cannot communicate with each other.

### Testing Domain Isolation

Run these in separate terminals:

**Terminal 1 (Domain 5):**
```powershell
$env:DDS_DOMAIN_ID = "5"
.\run-publisher.ps1
```

**Terminal 2 (Domain 10):**
```powershell
$env:DDS_DOMAIN_ID = "10"
.\run-subscriber.ps1
```

The subscriber should not receive messages from the publisher since they're on different domains.

### Testing Same Domain Communication

Run these in separate terminals:

**Terminal 1:**
```powershell
node examples/publisher.js HelloWorld 20
```

**Terminal 2:**
```powershell
node examples/subscriber.js HelloWorld 20
```

Both are on domain 20, so communication should work.

## Available Tests

- `node examples/test.js` - Basic functionality test
- `node examples/test-domain.js` - Domain ID and environment variable test

## Environment Setup Scripts

All scripts automatically set up the PATH to include required DLLs:

- `setup-env.ps1` - Setup environment for manual commands
- `run-publisher.ps1` - Run publisher with environment setup
- `run-subscriber.ps1` - Run subscriber with environment setup
