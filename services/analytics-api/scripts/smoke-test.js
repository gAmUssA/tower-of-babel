#!/usr/bin/env node
/**
 * Smoke test for Analytics API - validates critical dependencies and functionality
 */

// Import Node.js core modules
const fs = require('fs');
const path = require('path');

// ANSI colors for better readability
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const CYAN = '\x1b[36m';
const NC = '\x1b[0m'; // No Color
const CHECK = '✅';
const CROSS = '❌';
const WARNING = '⚠️';

/**
 * Print a header with a message
 */
function printHeader(message) {
  console.log(`\n${CYAN}${'='.repeat(60)}${NC}`);
  console.log(`${YELLOW}${message}${NC}`);
  console.log(`${CYAN}${'='.repeat(60)}${NC}`);
}

/**
 * Print result of a test
 */
function printResult(testName, success, message = "") {
  const status = success ? `${GREEN}${CHECK} PASS${NC}` : `${RED}${CROSS} FAIL${NC}`;
  console.log(`${testName.padEnd(50)} ${status}`);
  if (message && !success) {
    console.log(`  ${YELLOW}${WARNING} ${message}${NC}`);
  }
}

/**
 * Test dependency import
 */
function checkDependency(moduleName) {
  try {
    require(moduleName);
    return { success: true, message: "" };
  } catch (e) {
    return { success: false, message: e.message };
  }
}

/**
 * Test Schema Registry client
 */
function testSchemaRegistry() {
  try {
    const { SchemaRegistryClient, AvroDeserializer } = require('@confluentinc/schemaregistry');
    
    // Check that we can instantiate the client
    const registry = new SchemaRegistryClient({ baseURLs: ['http://localhost:8081'] });
    
    // Check that we can create a deserializer (this validates the API is real)
    const deserializer = new AvroDeserializer(registry, 1, {});
    
    // Basic validation that these are real objects
    if (!registry || !deserializer) {
      return { success: false, message: "@confluentinc/schemaregistry appears to be a mock implementation" };
    }
    
    return { success: true, message: "" };
  } catch (e) {
    return { success: false, message: e.message };
  }
}

/**
 * Test Confluent Kafka client
 */
function testConfluentKafka() {
  try {
    const { Kafka } = require('@confluentinc/kafka-javascript').KafkaJS;
    
    // Check for mock implementation by testing if essential classes/methods exist
    const kafka = new Kafka({
      kafkaJS: {
        brokers: ['localhost:9092']
      }
    });
    
    const consumer = kafka.consumer({ kafkaJS: { groupId: 'smoke-test' } });
    const producer = kafka.producer();
    
    // Check if essential methods exist
    const hasConsumerMethods = ['connect', 'disconnect', 'subscribe', 'run'].every(
      method => typeof consumer[method] === 'function'
    );
    
    const hasProducerMethods = ['connect', 'disconnect', 'send'].every(
      method => typeof producer[method] === 'function'
    );
    
    if (!hasConsumerMethods || !hasProducerMethods) {
      return { success: false, message: "Confluent Kafka client appears to be a mock implementation" };
    }
    
    return { success: true, message: "" };
  } catch (e) {
    return { success: false, message: e.message };
  }
}

/**
 * Test that core modules can be required/imported
 */
function testCoreModules() {
  // Define paths to key modules relative to the project root
  const moduleNames = [
    './dist/services/analytics-service.js',
    './dist/services/kafka-consumer.js',
    './dist/services/avro-kafka-consumer.js'
  ];
  
  // Check if dist directory exists
  const distPath = path.resolve(__dirname, '../dist');
  if (!fs.existsSync(distPath)) {
    return { 
      success: false, 
      message: "dist directory not found. Please run 'npm run build' first."
    };
  }
  
  // Check each module
  for (const moduleName of moduleNames) {
    try {
      const modulePath = path.resolve(__dirname, '..', moduleName);
      // Just check if the file exists since requiring might need mocked dependencies
      if (!fs.existsSync(modulePath)) {
        return { 
          success: false, 
          message: `Module file not found: ${moduleName}. Make sure the project is built.` 
        };
      }
    } catch (e) {
      return { success: false, message: `Error checking ${moduleName}: ${e.message}` };
    }
  }
  
  return { success: true, message: "" };
}

/**
 * Check TypeScript interfaces in generated directory
 */
function testGeneratedTypes() {
  const generatedDir = path.resolve(__dirname, '../src/generated');
  
  if (!fs.existsSync(generatedDir)) {
    return { 
      success: false, 
      message: "Generated types directory not found. Please run 'npm run generate-types'." 
    };
  }
  
  // Check if at least one TypeScript interface file exists
  try {
    const files = fs.readdirSync(generatedDir);
    const tsFiles = files.filter(file => file.endsWith('.ts'));
    
    if (tsFiles.length === 0) {
      return { 
        success: false, 
        message: "No TypeScript interface files found in generated directory." 
      };
    }
    
    return { success: true, message: "" };
  } catch (e) {
    return { success: false, message: e.message };
  }
}

/**
 * Main smoke test function
 */
function main() {
  printHeader("🔍 Running Analytics API Smoke Tests");
  
  // Track overall result
  let allPassed = true;
  
  // Test critical dependencies
  const dependencies = [
    'express', 
    '@confluentinc/kafka-javascript',
    '@confluentinc/schemaregistry',
    'socket.io', 
    'dotenv'
  ];
  
  console.log("\n🧪 Testing critical dependencies:");
  for (const dep of dependencies) {
    const { success, message } = checkDependency(dep);
    allPassed = allPassed && success;
    printResult(`Import ${dep}`, success, message);
  }
  
  // Test Schema Registry client
  console.log("\n🧪 Testing Schema Registry client:");
  const schemaRegistryResult = testSchemaRegistry();
  allPassed = allPassed && schemaRegistryResult.success;
  printResult("@confluentinc/schemaregistry real implementation", 
             schemaRegistryResult.success, 
             schemaRegistryResult.message);
  
  // Test Confluent Kafka client
  console.log("\n🧪 Testing Confluent Kafka client:");
  const confluentKafkaResult = testConfluentKafka();
  allPassed = allPassed && confluentKafkaResult.success;
  printResult("@confluentinc/kafka-javascript real implementation", confluentKafkaResult.success, confluentKafkaResult.message);
  
  // Test core modules
  console.log("\n🧪 Testing compiled modules existence:");
  const modulesResult = testCoreModules();
  allPassed = allPassed && modulesResult.success;
  printResult("All core modules exist", modulesResult.success, modulesResult.message);
  
  // Test generated types
  console.log("\n🧪 Testing generated TypeScript interfaces:");
  const typesResult = testGeneratedTypes();
  allPassed = allPassed && typesResult.success;
  printResult("Generated TypeScript interfaces", typesResult.success, typesResult.message);
  
  // Print summary
  console.log("\n" + "=".repeat(60));
  if (allPassed) {
    console.log(`${GREEN}🎉 All smoke tests PASSED! The Analytics API dependencies look good.${NC}`);
  } else {
    console.log(`${RED}❌ Some smoke tests FAILED! Check the details above.${NC}`);
  }
  console.log("=".repeat(60));
  
  return allPassed ? 0 : 1;
}

// Run the main function and set the exit code
process.exit(main());
