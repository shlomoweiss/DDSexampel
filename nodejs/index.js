const ddsAddon = require('./build/Release/dds_addon');

class DDSMessaging {
  constructor() {
    this.initialized = false;
    this.currentDomainId = null;
    this.currentTopicName = null;
  }

  /**
   * Initialize DDS with a topic name (uses environment variable DDS_DOMAIN_ID or default 0)
   * @param {string} topicName - The name of the DDS topic
   * @returns {boolean} - Success status
   */
  init(topicName) {
    const result = ddsAddon.init(topicName);
    this.initialized = (result === 1);
    if (this.initialized) {
      this.currentTopicName = topicName;
      this.currentDomainId = this._getDomainIdFromEnv();
    }
    return this.initialized;
  }

  /**
   * Initialize DDS with a topic name and specific domain ID
   * @param {string} topicName - The name of the DDS topic
   * @param {number} domainId - The DDS domain ID (0-232)
   * @returns {boolean} - Success status
   */
  initWithDomain(topicName, domainId) {
    if (typeof domainId !== 'number' || domainId < 0 || domainId > 232) {
      throw new Error('Domain ID must be a number between 0 and 232');
    }
    
    const result = ddsAddon.initWithDomain(topicName, domainId);
    this.initialized = (result === 1);
    if (this.initialized) {
      this.currentTopicName = topicName;
      this.currentDomainId = domainId;
    }
    return this.initialized;
  }

  /**
   * Get the current domain ID from environment variable or return default
   * @private
   * @returns {number} - Domain ID
   */
  _getDomainIdFromEnv() {
    const envDomainId = process.env.DDS_DOMAIN_ID;
    return envDomainId ? parseInt(envDomainId, 10) : 0;
  }

  /**
   * Get current configuration information
   * @returns {Object} - Current configuration
   */
  getConfig() {
    return {
      initialized: this.initialized,
      domainId: this.currentDomainId,
      topicName: this.currentTopicName
    };
  }

  /**
   * Write a message with index (legacy method)
   * @param {number} index - Message index
   * @param {string} message - Message content
   * @returns {boolean} - Success status
   */
  write(index, message) {
    if (!this.initialized) {
      throw new Error('DDS not initialized. Call init() first.');
    }
    return ddsAddon.write(index, message) === 1;
  }

  /**
   * Write a HelloWorld struct
   * @param {Object} helloWorld - Object with index and message properties
   * @returns {boolean} - Success status
   */
  writeStruct(helloWorld) {
    if (!this.initialized) {
      throw new Error('DDS not initialized. Call init() first.');
    }
    if (!helloWorld || typeof helloWorld.index !== 'number' || typeof helloWorld.message !== 'string') {
      throw new Error('HelloWorld object must have index (number) and message (string) properties');
    }
    return ddsAddon.writeStruct(helloWorld) === 1;
  }

  /**
   * Take a message (legacy method)
   * @returns {Object|null} - Object with success, index, and message properties
   */
  take() {
    if (!this.initialized) {
      throw new Error('DDS not initialized. Call init() first.');
    }
    const result = ddsAddon.take();
    return result.success === 1 ? { index: result.index, message: result.message } : null;
  }

  /**
   * Take a HelloWorld struct
   * @returns {Object|null} - Object with index and message properties
   */
  takeStruct() {
    if (!this.initialized) {
      throw new Error('DDS not initialized. Call init() first.');
    }
    const result = ddsAddon.takeStruct();
    return result.success === 1 ? { index: result.index, message: result.message } : null;
  }

  /**
   * Take a message and return it directly
   * @returns {Object|null} - Object with index and message properties
   */
  takeMessage() {
    if (!this.initialized) {
      throw new Error('DDS not initialized. Call init() first.');
    }
    const result = ddsAddon.takeMessage();
    return result.message ? { index: result.index, message: result.message } : null;
  }

  /**
   * Shutdown DDS
   */
  shutdown() {
    if (this.initialized) {
      ddsAddon.shutdown();
      this.initialized = false;
    }
  }
}

module.exports = DDSMessaging;
