#!/usr/bin/env tsx

/**
 * Generate API Specifications Script
 * 
 * Generates OpenAPI specification files (YAML) from all microservices.
 * 
 * This script:
 * - Imports swagger specs from all services
 * - Converts them to YAML format
 * - Saves them as API-SPECIFICATION.yml in each service directory
 * 
 * Requirements:
 *   - Node.js 18+
 *   - TypeScript services must be compiled or tsx must be available
 * 
 * Usage:
 *   npm run generate-api-specs
 *   or
 *   tsx scripts/generate-api-specs.ts
 * 
 * Output:
 *   - services/restaurant-menu-service/API-SPECIFICATION.yml
 *   - services/order-service/API-SPECIFICATION.yml
 *   - services/driver-location-service/API-SPECIFICATION.yml
 *   - services/notification-service/API-SPECIFICATION.yml
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import yaml from 'js-yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

interface ServiceConfig {
  name: string;
  importPath: string;
  serviceDir: string;
}

const services: ServiceConfig[] = [
  {
    name: 'Restaurant Menu Service',
    importPath: '../services/restaurant-menu-service/src/config/swagger.ts',
    serviceDir: 'restaurant-menu-service',
  },
  {
    name: 'Order Service',
    importPath: '../services/order-service/src/config/swagger.ts',
    serviceDir: 'order-service',
  },
  {
    name: 'Driver Location Service',
    importPath: '../services/driver-location-service/src/config/swagger.ts',
    serviceDir: 'driver-location-service',
  },
  {
    name: 'Notification Service',
    importPath: '../services/notification-service/src/config/swagger.ts',
    serviceDir: 'notification-service',
  },
];

async function generateSpecs() {
  console.log('🚀 Generating API specifications...\n');

  for (const service of services) {
    try {
      console.log(`📝 Processing ${service.name}...`);

      // Dynamic import of the swagger spec
      const swaggerModule = await import(service.importPath);
      const swaggerSpec = swaggerModule.swaggerSpec;

      if (!swaggerSpec) {
        throw new Error(`swaggerSpec not found in ${service.importPath}`);
      }

      // Generate YAML
      const yamlContent = yaml.dump(swaggerSpec, {
        indent: 2,
        lineWidth: -1,
        noRefs: false,
        sortKeys: false,
      });

      // Write API-SPECIFICATION.yml file in service directory
      const serviceDir = path.join(rootDir, 'services', service.serviceDir);
      const yamlPath = path.join(serviceDir, 'API-SPECIFICATION.yml');
      fs.writeFileSync(yamlPath, yamlContent, 'utf8');
      console.log(`   ✅ Generated: ${path.relative(rootDir, yamlPath)}`);

      console.log('');
    } catch (error) {
      console.error(`   ❌ Error processing ${service.name}:`, error);
      if (error instanceof Error) {
        console.error(`   ${error.message}`);
      }
      console.log('');
    }
  }

  console.log('✨ API specifications generated successfully!');
}

// Run the script
generateSpecs().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
