const DDSMessaging = require('../index');

class Subscriber {
  constructor(topicName = 'HelloWorldTopic', domainId = null) {
    this.dds = new DDSMessaging();
    this.topicName = topicName;
    this.domainId = domainId;
    this.messagesReceived = 0;
    this.intervalId = null;
    this.running = false;
  }

  async start() {
    console.log('Initializing DDS Subscriber...');
    
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
    console.log(`Subscriber initialized:`);
    console.log(`  - Topic: ${config.topicName}`);
    console.log(`  - Domain ID: ${config.domainId}`);
    
    this.running = true;
    
    // Start polling for messages every 500ms
    this.intervalId = setInterval(() => {
      this.checkForMessages();
    }, 500);

    // Handle graceful shutdown
    process.on('SIGINT', () => {
      this.stop();
    });

    console.log('Subscriber started. Waiting for messages... Press Ctrl+C to stop.');
    return true;
  }

  checkForMessages() {
    if (!this.running) return;

    try {
      // Try to take a message using the struct method
      const result = this.dds.takeStruct();
      
      if (result) {
        this.messagesReceived++;
        console.log(`📨 Received message ${this.messagesReceived}:`);
        console.log(`   Index: ${result.index}`);
        console.log(`   Message: "${result.message}"`);
        console.log(`   Time: ${new Date().toISOString()}`);
        console.log('   ---');
      }
      
      // Also try the legacy take method as backup
      const legacyResult = this.dds.take();
      if (legacyResult && (!result || legacyResult.index !== result.index)) {
        this.messagesReceived++;
        console.log(`📨 Received legacy message ${this.messagesReceived}:`);
        console.log(`   Index: ${legacyResult.index}`);
        console.log(`   Message: "${legacyResult.message}"`);
        console.log(`   Time: ${new Date().toISOString()}`);
        console.log('   ---');
      }

      // Also try takeMessage method
      const messageResult = this.dds.takeMessage();
      if (messageResult && (!result || messageResult.index !== result.index)) {
        this.messagesReceived++;
        console.log(`📨 Received direct message ${this.messagesReceived}:`);
        console.log(`   Index: ${messageResult.index}`);
        console.log(`   Message: "${messageResult.message}"`);
        console.log(`   Time: ${new Date().toISOString()}`);
        console.log('   ---');
      }
      
    } catch (error) {
      console.error('Error checking for messages:', error.message);
    }
  }

  stop() {
    console.log('\nShutting down subscriber...');
    this.running = false;
    
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    
    console.log(`Total messages received: ${this.messagesReceived}`);
    this.dds.shutdown();
    console.log('Subscriber shutdown complete');
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
  
  console.log('=== DDS Subscriber ===');
  if (process.env.DDS_DOMAIN_ID) {
    console.log(`Environment DDS_DOMAIN_ID: ${process.env.DDS_DOMAIN_ID}`);
  }
  
  const subscriber = new Subscriber(topicName, domainId);
  
  try {
    await subscriber.start();
    
    // Keep the process alive
    setInterval(() => {}, 1000);
    
  } catch (error) {
    console.error('Subscriber error:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = Subscriber;
