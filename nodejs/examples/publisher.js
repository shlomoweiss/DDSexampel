const DDSMessaging = require('../index');

class Publisher {
  constructor(topicName = 'HelloWorldTopic', domainId = null) {
    this.dds = new DDSMessaging();
    this.topicName = topicName;
    this.domainId = domainId;
    this.messageCount = 0;
    this.intervalId = null;
  }

  async start() {
    console.log('Initializing DDS Publisher...');
    
    let success = false;
    if (this.domainId !== null) {
      console.log(`Using explicit domain ID: ${this.domainId}`);
      success = this.dds.initWithDomain(this.topicName, this.domainId);
    } else {
      const envDomainId = process.env.DDS_DOMAIN_ID;
      if (envDomainId) {
        console.log(`Using domain ID from environment: ${envDomainId}`);
      } else {
        console.log('Using default domain ID: 0');
      }
      success = this.dds.init(this.topicName);
    }
    
    if (!success) {
      console.error('Failed to initialize DDS');
      return false;
    }
    
    const config = this.dds.getConfig();
    console.log(`Publisher initialized:`);
    console.log(`  - Topic: ${config.topicName}`);
    console.log(`  - Domain ID: ${config.domainId}`);
    
    // Start publishing messages every 2 seconds
    this.intervalId = setInterval(() => {
      this.publishMessage();
    }, 2000);

    // Handle graceful shutdown
    process.on('SIGINT', () => {
      this.stop();
    });

    console.log('Publisher started. Press Ctrl+C to stop.');
    return true;
  }

  publishMessage() {
    this.messageCount++;
    
    const helloWorld = {
      index: this.messageCount,
      message: `Hello World from Node.js! Message #${this.messageCount} at ${new Date().toISOString()}`
    };

    console.log(`Publishing message ${this.messageCount}: "${helloWorld.message}"`);
    
    try {
      const success = this.dds.writeStruct(helloWorld);
      if (success) {
        console.log(`✓ Message ${this.messageCount} published successfully`);
      } else {
        console.error(`✗ Failed to publish message ${this.messageCount}`);
      }
    } catch (error) {
      console.error('Error publishing message:', error.message);
    }
  }

  stop() {
    console.log('\nShutting down publisher...');
    
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    
    this.dds.shutdown();
    console.log('Publisher shutdown complete');
    process.exit(0);
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const topicName = args[0] || 'HelloWorldTopic';
  const domainId = args[1] ? parseInt(args[1], 10) : null;
  
  if (domainId !== null && (isNaN(domainId) || domainId < 0 || domainId > 232)) {
    console.error('Invalid domain ID. Must be a number between 0 and 232.');
    process.exit(1);
  }
  
  console.log('=== DDS Publisher ===');
  if (process.env.DDS_DOMAIN_ID) {
    console.log(`Environment DDS_DOMAIN_ID: ${process.env.DDS_DOMAIN_ID}`);
  }
  
  const publisher = new Publisher(topicName, domainId);
  
  try {
    await publisher.start();
  } catch (error) {
    console.error('Publisher error:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = Publisher;
