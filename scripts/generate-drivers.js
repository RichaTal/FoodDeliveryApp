#!/usr/bin/env node

/**
 * Generate Test Drivers Script
 * 
 * Creates driver records in the database for testing GPS location simulator.
 * 
 * Requirements:
 *   - Node.js 18+ (for native fetch API)
 *   - PostgreSQL database must be accessible
 *   - Database connection via environment variables or direct connection
 * 
 * Usage:
 *   node scripts/generate-drivers.js [options]
 * 
 * Examples:
 *   # Generate 50 drivers (default)
 *   node scripts/generate-drivers.js
 * 
 *   # Generate 1000 drivers
 *   node scripts/generate-drivers.js --count 1000
 * 
 *   # Use custom database connection
 *   node scripts/generate-drivers.js --db-url "postgresql://user:pass@localhost:5432/fooddelivery"
 * 
 * Options:
 *   --count <n>        Number of drivers to generate (default: 50)
 *   --db-url <url>     PostgreSQL connection URL (default: from env vars)
 *   --help             Show this help message
 */

const { Client } = require('pg');

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  count: 50,
  dbUrl: null,
};

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--help' || arg === '-h') {
    const helpText = require('fs').readFileSync(__filename, 'utf8').match(/\/\*\*[\s\S]*?\*\//);
    if (helpText) {
      console.log(helpText[0]);
    }
    process.exit(0);
  } else if (arg === '--count' && args[i + 1]) {
    options.count = parseInt(args[++i], 10);
  } else if (arg === '--db-url' && args[i + 1]) {
    options.dbUrl = args[++i];
  }
}

/**
 * Generate a UUID v4 (simple implementation)
 */
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Generate random driver data
 */
function generateDriverData() {
  const firstNames = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Jamie', 'Riley', 'Avery', 'Quinn'];
  const lastNames = ['Rivera', 'Chen', 'Lee', 'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller'];
  const vehicles = [
    'Honda PCX 150 Scooter',
    'Yamaha NMAX 155 Scooter',
    'Trek FX3 Disc Bicycle',
    'Giant Escape 3 Bicycle',
    'Vespa Primavera 125',
    'Piaggio Liberty 150',
    'Specialized Sirrus Bicycle',
    'Cannondale Quick Bicycle',
  ];
  
  const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
  const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
  const vehicle = vehicles[Math.floor(Math.random() * vehicles.length)];
  const phone = `+1-555-${String(Math.floor(1000 + Math.random() * 9000))}`;
  
  return {
    id: generateUUID(),
    name: `${firstName} ${lastName}`,
    phone,
    vehicle,
  };
}

/**
 * Main execution
 */
async function main() {
  console.log('🚀 Generate Test Drivers');
  console.log('='.repeat(80));
  console.log(`\nGenerating ${options.count} driver records...`);
  
  // Database connection configuration
  const dbConfig = options.dbUrl
    ? { connectionString: options.dbUrl }
    : {
        host: process.env.POSTGRES_HOST || 'localhost',
        port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
        database: process.env.POSTGRES_DB || 'driver_db',
        user: process.env.POSTGRES_USER || 'postgres',
        password: process.env.POSTGRES_PASSWORD || 'postgres123',
      };
  
  const client = new Client(dbConfig);
  
  try {
    // Connect to database
    console.log('\n📋 Connecting to database...');
    await client.connect();
    console.log('   ✓ Connected');
    
    // Check if drivers table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'drivers'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.error('\n❌ Error: drivers table does not exist.');
      console.error('   Please ensure the database schema is initialized.');
      process.exit(1);
    }
    
    // Generate drivers
    console.log(`\n👥 Generating ${options.count} drivers...`);
    const drivers = [];
    for (let i = 0; i < options.count; i++) {
      drivers.push(generateDriverData());
    }
    
    // Insert drivers in batches
    const batchSize = 100;
    let inserted = 0;
    let skipped = 0;
    
    for (let i = 0; i < drivers.length; i += batchSize) {
      const batch = drivers.slice(i, i + batchSize);
      const values = batch.map((d, idx) => {
        const baseIdx = i + idx;
        return `($${baseIdx * 5 + 1}, $${baseIdx * 5 + 2}, $${baseIdx * 5 + 3}, $${baseIdx * 5 + 4}, $${baseIdx * 5 + 5})`;
      }).join(', ');
      
      const params = batch.flatMap(d => [d.id, d.name, d.phone, d.vehicle, true]);
      
      try {
        await client.query(`
          INSERT INTO drivers (id, name, phone, vehicle, is_active)
          VALUES ${values}
          ON CONFLICT (phone) DO NOTHING
        `, params);
        
        inserted += batch.length;
        process.stdout.write(`\r   Progress: ${Math.min(i + batchSize, drivers.length)}/${drivers.length}`);
      } catch (error) {
        // Check if it's a unique constraint violation (phone)
        if (error.code === '23505') {
          skipped += batch.length;
        } else {
          throw error;
        }
      }
    }
    
    console.log('\n');
    
    // Count total active drivers
    const countResult = await client.query(`
      SELECT COUNT(*) as count FROM drivers WHERE is_active = true
    `);
    const totalActive = parseInt(countResult.rows[0].count, 10);
    
    console.log('\n✅ Driver Generation Complete');
    console.log('='.repeat(80));
    console.log(`   Inserted:     ${inserted} drivers`);
    console.log(`   Skipped:      ${skipped} drivers (duplicate phones)`);
    console.log(`   Total Active: ${totalActive} drivers`);
    console.log('\n' + '='.repeat(80) + '\n');
    
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run
main();
