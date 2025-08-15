const DDSMessaging = require('../index');

async function testDomainIDFunctionality() {
  console.log('=== DDS Domain ID and Environment Variable Test ===\n');
  
  // Test 1: Default domain ID behavior
  console.log('1. Testing default domain ID behavior...');
  const dds1 = new DDSMessaging();
  
  if (dds1.init('TestTopic1')) {
    const config1 = dds1.getConfig();
    console.log(`✓ Default initialization successful`);
    console.log(`  - Domain ID: ${config1.domainId}`);
    console.log(`  - Topic: ${config1.topicName}`);
    dds1.shutdown();
  } else {
    console.log('✗ Default initialization failed');
  }
  console.log('');
  
  // Test 2: Explicit domain ID
  console.log('2. Testing explicit domain ID...');
  const dds2 = new DDSMessaging();
  const testDomainId = 5;
  
  if (dds2.initWithDomain('TestTopic2', testDomainId)) {
    const config2 = dds2.getConfig();
    console.log(`✓ Explicit domain ID initialization successful`);
    console.log(`  - Domain ID: ${config2.domainId}`);
    console.log(`  - Topic: ${config2.topicName}`);
    dds2.shutdown();
  } else {
    console.log('✗ Explicit domain ID initialization failed');
  }
  console.log('');
  
  // Test 3: Environment variable override
  console.log('3. Testing environment variable override...');
  const originalEnv = process.env.DDS_DOMAIN_ID;
  process.env.DDS_DOMAIN_ID = '10';
  
  const dds3 = new DDSMessaging();
  if (dds3.init('TestTopic3')) {
    const config3 = dds3.getConfig();
    console.log(`✓ Environment variable override successful`);
    console.log(`  - Domain ID: ${config3.domainId} (from DDS_DOMAIN_ID env var)`);
    console.log(`  - Topic: ${config3.topicName}`);
    dds3.shutdown();
  } else {
    console.log('✗ Environment variable override failed');
  }
  
  // Restore original environment
  if (originalEnv !== undefined) {
    process.env.DDS_DOMAIN_ID = originalEnv;
  } else {
    delete process.env.DDS_DOMAIN_ID;
  }
  console.log('');
  
  // Test 4: Domain isolation test
  console.log('4. Testing domain isolation...');
  console.log('   (Different domain IDs should not communicate)');
  
  const publisherDomain = 20;
  const subscriberDomain = 21;
  
  const publisher = new DDSMessaging();
  const subscriber = new DDSMessaging();
  
  try {
    // Initialize on different domains
    console.log(`   Initializing publisher on domain ${publisherDomain}...`);
    if (!publisher.initWithDomain('IsolationTest', publisherDomain)) {
      throw new Error('Publisher initialization failed');
    }
    
    console.log(`   Initializing subscriber on domain ${subscriberDomain}...`);
    if (!subscriber.initWithDomain('IsolationTest', subscriberDomain)) {
      throw new Error('Subscriber initialization failed');
    }
    
    // Wait for potential discovery
    console.log('   Waiting for potential discovery...');
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Publisher sends message
    console.log('   Publisher sending test message...');
    const testMessage = { index: 999, message: 'Isolation test message' };
    
    if (publisher.writeStruct(testMessage)) {
      console.log('   ✓ Message sent successfully');
      
      // Subscriber tries to receive (should fail due to different domains)
      await new Promise(resolve => setTimeout(resolve, 500));
      const result = subscriber.takeStruct();
      
      if (!result) {
        console.log('   ✓ Domain isolation working - no message received (expected)');
      } else {
        console.log('   ⚠ Domain isolation failed - message received unexpectedly');
      }
    } else {
      console.log('   ✗ Failed to send message');
    }
    
  } catch (error) {
    console.error('   Error during isolation test:', error.message);
  } finally {
    publisher.shutdown();
    subscriber.shutdown();
  }
  console.log('');
  
  // Test 5: Same domain communication test
  console.log('5. Testing same domain communication...');
  const sameDomain = 30;
  
  const pub = new DDSMessaging();
  const sub = new DDSMessaging();
  
  try {
    console.log(`   Both using domain ${sameDomain}...`);
    if (!pub.initWithDomain('SameTest', sameDomain) || !sub.initWithDomain('SameTest', sameDomain)) {
      throw new Error('Initialization failed');
    }
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const msg = { index: 777, message: 'Same domain test' };
    console.log('   Sending message...');
    
    if (pub.writeStruct(msg)) {
      await new Promise(resolve => setTimeout(resolve, 200));
      const received = sub.takeStruct();
      
      if (received && received.index === msg.index) {
        console.log('   ✓ Same domain communication working');
        console.log(`     Received: Index=${received.index}, Message="${received.message}"`);
      } else {
        console.log('   ⚠ Same domain communication failed - no message received');
      }
    }
    
  } catch (error) {
    console.error('   Error during same domain test:', error.message);
  } finally {
    pub.shutdown();
    sub.shutdown();
  }
  
  console.log('\n=== Domain ID Test Complete ===');
}

if (require.main === module) {
  // Set up environment
  process.env.PATH += ";C:\\fastdds 3.2.2\\bin\\x64Win64VS2019";
  process.env.PATH += ";C:\\cpp-prj\\DDSexampel\\DDSmessage\\build\\Release";
  
  testDomainIDFunctionality().catch(console.error);
}

module.exports = testDomainIDFunctionality;
