const DDSMessaging = require('../index');

async function testDDSMessaging() {
  console.log('=== DDS Messaging Test ===\n');
  
  const publisher = new DDSMessaging();
  const subscriber = new DDSMessaging();
  
  const topicName = 'TestTopic';
  
  try {
    // Initialize publisher
    console.log('1. Initializing publisher...');
    if (!publisher.init(topicName)) {
      throw new Error('Failed to initialize publisher');
    }
    console.log('✓ Publisher initialized\n');
    
    // Initialize subscriber  
    console.log('2. Initializing subscriber...');
    if (!subscriber.init(topicName)) {
      throw new Error('Failed to initialize subscriber');
    }
    console.log('✓ Subscriber initialized\n');
    
    // Wait a moment for DDS discovery
    console.log('3. Waiting for DDS discovery...');
    await new Promise(resolve => setTimeout(resolve, 2000));
    console.log('✓ Discovery complete\n');
    
    // Test publishing and receiving messages
    console.log('4. Testing message exchange...\n');
    
    for (let i = 1; i <= 5; i++) {
      const testMessage = {
        index: i,
        message: `Test message ${i} - ${new Date().toISOString()}`
      };
      
      console.log(`Publishing: Index=${testMessage.index}, Message="${testMessage.message}"`);
      
      if (publisher.writeStruct(testMessage)) {
        console.log('✓ Message published successfully');
        
        // Try to receive the message
        let received = false;
        let attempts = 0;
        const maxAttempts = 10;
        
        while (!received && attempts < maxAttempts) {
          await new Promise(resolve => setTimeout(resolve, 100));
          
          const result = subscriber.takeStruct();
          if (result) {
            console.log(`✓ Received: Index=${result.index}, Message="${result.message}"`);
            received = true;
          }
          attempts++;
        }
        
        if (!received) {
          console.log('⚠ Message not received within timeout');
        }
      } else {
        console.log('✗ Failed to publish message');
      }
      
      console.log('---');
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    console.log('\n5. Testing legacy methods...\n');
    
    // Test legacy write/take methods
    console.log('Testing legacy write method...');
    if (publisher.write(100, 'Legacy test message')) {
      console.log('✓ Legacy message published');
      
      await new Promise(resolve => setTimeout(resolve, 200));
      
      const legacyResult = subscriber.take();
      if (legacyResult) {
        console.log(`✓ Legacy message received: Index=${legacyResult.index}, Message="${legacyResult.message}"`);
      } else {
        console.log('⚠ Legacy message not received');
      }
    } else {
      console.log('✗ Failed to publish legacy message');
    }
    
    console.log('\nTesting takeMessage method...');
    publisher.writeStruct({ index: 200, message: 'Direct message test' });
    await new Promise(resolve => setTimeout(resolve, 200));
    
    const directResult = subscriber.takeMessage();
    if (directResult) {
      console.log(`✓ Direct message received: Index=${directResult.index}, Message="${directResult.message}"`);
    } else {
      console.log('⚠ Direct message not received');
    }
    
  } catch (error) {
    console.error('Test error:', error.message);
  } finally {
    // Cleanup
    console.log('\n6. Cleaning up...');
    publisher.shutdown();
    subscriber.shutdown();
    console.log('✓ Cleanup complete');
    console.log('\n=== Test Complete ===');
  }
}

if (require.main === module) {
  testDDSMessaging().catch(console.error);
}

module.exports = testDDSMessaging;
