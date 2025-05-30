#!/usr/bin/env node

/**
 * Simple script to generate TypeScript interfaces from Avro schemas
 */

const fs = require('fs');
const path = require('path');

// Define paths
const schemaDir = path.resolve(__dirname, '../../../../schemas/v1');
const outputDir = path.resolve(__dirname, '../generated');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Avro to TypeScript type mapping
const typeMapping = {
  'string': 'string',
  'int': 'number',
  'long': 'number',
  'float': 'number',
  'double': 'number',
  'boolean': 'boolean',
  'bytes': 'Buffer',
  'null': 'null',
};

/**
 * Convert Avro type to TypeScript type
 */
function avroToTsType(avroType) {
  if (typeof avroType === 'string') {
    return typeMapping[avroType] || avroType;
  } else if (Array.isArray(avroType)) {
    // Handle union types
    if (avroType.includes('null')) {
      // If null is in the union, make the type optional
      const nonNullTypes = avroType.filter(t => t !== 'null');
      if (nonNullTypes.length === 1) {
        return `${avroToTsType(nonNullTypes[0])} | null`;
      } else {
        const types = nonNullTypes.map(t => avroToTsType(t)).join(' | ');
        return `(${types}) | null`;
      }
    } else {
      const types = avroType.map(t => avroToTsType(t)).join(' | ');
      return types;
    }
  } else if (typeof avroType === 'object') {
    // Handle complex types
    if (avroType.type === 'array') {
      const itemType = avroToTsType(avroType.items);
      return `${itemType}[]`;
    } else if (avroType.type === 'map') {
      const valueType = avroToTsType(avroType.values);
      return `{ [key: string]: ${valueType} }`;
    } else if (avroType.type === 'record') {
      // For nested records, just use the name
      return avroType.name;
    }
  }
  return 'any'; // Default to any for unknown types
}

/**
 * Generate TypeScript interface from Avro schema
 */
function generateInterface(schema) {
  const recordName = schema.name;
  const namespace = schema.namespace || '';
  const fields = schema.fields || [];
  
  // Generate interface definition
  let interfaceContent = `/**\n * ${schema.doc || 'Generated from Avro schema'}\n */\nexport interface ${recordName} {\n`;
  
  // Generate field definitions
  for (const field of fields) {
    const fieldName = field.name;
    const fieldType = avroToTsType(field.type);
    const fieldDoc = field.doc || '';
    
    // Add field with documentation
    interfaceContent += `  /**\n   * ${fieldDoc}\n   */\n`;
    
    // Handle default values with optional fields
    if ('default' in field) {
      interfaceContent += `  ${fieldName}?: ${fieldType};\n`;
    } else {
      interfaceContent += `  ${fieldName}: ${fieldType};\n`;
    }
  }
  
  interfaceContent += '}\n';
  
  // Write to file
  const outputFile = path.join(outputDir, `${recordName}.ts`);
  fs.writeFileSync(outputFile, interfaceContent);
  console.log(`Generated ${outputFile}`);
  
  return { name: recordName, namespace };
}

/**
 * Generate index.ts file to export all interfaces
 */
function generateIndex(interfaces) {
  let indexContent = '// Generated TypeScript interfaces from Avro schemas\n\n';
  
  // Add exports for each interface
  for (const iface of interfaces) {
    indexContent += `export { ${iface.name} } from './${iface.name}';\n`;
  }
  
  // Write to file
  const indexFile = path.join(outputDir, 'index.ts');
  fs.writeFileSync(indexFile, indexContent);
  console.log(`Generated ${indexFile}`);
}

/**
 * Main function
 */
function main() {
  console.log('Generating TypeScript interfaces from Avro schemas...');
  
  // Get all schema files
  const schemaFiles = fs.readdirSync(schemaDir)
    .filter(file => file.endsWith('.avsc'))
    .map(file => path.join(schemaDir, file));
  
  const interfaces = [];
  
  // Process each schema file
  for (const schemaFile of schemaFiles) {
    console.log(`Processing ${schemaFile}...`);
    const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
    const iface = generateInterface(schema);
    interfaces.push(iface);
  }
  
  // Generate index.ts
  generateIndex(interfaces);
  
  console.log('TypeScript interface generation complete!');
}

// Run the script
main();
