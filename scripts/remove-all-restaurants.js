#!/usr/bin/env node

/**
 * Script to Remove All Restaurants and Their Menus from Database
 * 
 * This script will:
 *   1. Delete all orders (since they reference restaurants without CASCADE)
 *   2. Delete all restaurants (which will cascade delete menu_categories and menu_items)
 * 
 * Requirements:
 *   - Node.js 18+
 *   - PostgreSQL database must be running
 *   - Environment variables or defaults for DB connection
 *   - pg package installed (npm install pg dotenv)
 * 
 * Usage:
 *   node scripts/remove-all-restaurants.js [--confirm]
 * 
 * Options:
 *   --confirm    Skip confirmation prompt (useful for automation)
 *   --help       Show this help message
 */

const pg = require('pg');
const dotenv = require('dotenv');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

dotenv.config();

const { Pool } = pg;

// Database connection configuration
const pool = new Pool({
  host: process.env['POSTGRES_HOST'] || 'localhost',
  port: parseInt(process.env['POSTGRES_PORT'] || '5432', 10),
  user: process.env['POSTGRES_USER'] || 'foodapp',
  password: process.env['POSTGRES_PASSWORD'] || 'foodapp',
  database: process.env['POSTGRES_DB'] || 'restaurant_db',
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

pool.on('error', (err) => {
  console.error('[DB] Unexpected pool error:', err.message);
});

/**
 * Get counts of records before deletion
 */
async function getCounts() {
  const client = await pool.connect();
  try {
    const restaurantCount = await client.query('SELECT COUNT(*) as count FROM restaurants');
    const menuCategoryCount = await client.query('SELECT COUNT(*) as count FROM menu_categories');
    const menuItemCount = await client.query('SELECT COUNT(*) as count FROM menu_items');
    const orderCount = await client.query('SELECT COUNT(*) as count FROM orders');
    const orderItemCount = await client.query('SELECT COUNT(*) as count FROM order_items');

    return {
      restaurants: parseInt(restaurantCount.rows[0].count, 10),
      menuCategories: parseInt(menuCategoryCount.rows[0].count, 10),
      menuItems: parseInt(menuItemCount.rows[0].count, 10),
      orders: parseInt(orderCount.rows[0].count, 10),
      orderItems: parseInt(orderItemCount.rows[0].count, 10),
    };
  } finally {
    client.release();
  }
}

/**
 * Delete all restaurants and their menus
 */
async function deleteAllRestaurants() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Delete orders first (they reference restaurants without CASCADE)
    console.log('Deleting orders...');
    const orderItemsResult = await client.query('DELETE FROM order_items');
    console.log(`  ✓ Deleted ${orderItemsResult.rowCount} order items`);

    const ordersResult = await client.query('DELETE FROM orders');
    console.log(`  ✓ Deleted ${ordersResult.rowCount} orders`);

    // Delete restaurants (this will cascade delete menu_categories and menu_items)
    console.log('Deleting restaurants (this will cascade delete menus)...');
    const restaurantsResult = await client.query('DELETE FROM restaurants');
    console.log(`  ✓ Deleted ${restaurantsResult.rowCount} restaurants`);

    // Verify menu items and categories were cascade deleted
    const remainingMenuItems = await client.query('SELECT COUNT(*) as count FROM menu_items');
    const remainingMenuCategories = await client.query('SELECT COUNT(*) as count FROM menu_categories');

    if (parseInt(remainingMenuItems.rows[0].count, 10) > 0) {
      console.warn(`  ⚠ Warning: ${remainingMenuItems.rows[0].count} menu items still exist`);
    } else {
      console.log('  ✓ All menu items deleted (cascade)');
    }

    if (parseInt(remainingMenuCategories.rows[0].count, 10) > 0) {
      console.warn(`  ⚠ Warning: ${remainingMenuCategories.rows[0].count} menu categories still exist`);
    } else {
      console.log('  ✓ All menu categories deleted (cascade)');
    }

    await client.query('COMMIT');
    console.log('\n✓ Successfully deleted all restaurants and their menus');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Prompt user for confirmation
 */
function askConfirmation() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question('Are you sure you want to delete ALL restaurants and their menus? (yes/no): ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y');
    });
  });
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    const helpText = fs.readFileSync(__filename, 'utf8');
    const match = helpText.match(/\/\*\*[\s\S]*?\*\//);
    if (match) {
      console.log(match[0]);
    }
    process.exit(0);
  }

  const skipConfirmation = args.includes('--confirm');

  try {
    console.log('Connecting to database...');
    await pool.query('SELECT 1'); // Test connection
    console.log('✓ Connected to database\n');

    // Get counts before deletion
    console.log('Counting existing records...');
    const counts = await getCounts();
    console.log(`  Restaurants: ${counts.restaurants}`);
    console.log(`  Menu Categories: ${counts.menuCategories}`);
    console.log(`  Menu Items: ${counts.menuItems}`);
    console.log(`  Orders: ${counts.orders}`);
    console.log(`  Order Items: ${counts.orderItems}\n`);

    if (counts.restaurants === 0) {
      console.log('No restaurants found in database. Nothing to delete.');
      await pool.end();
      process.exit(0);
    }

    // Ask for confirmation unless --confirm flag is set
    if (!skipConfirmation) {
      const confirmed = await askConfirmation();
      if (!confirmed) {
        console.log('Operation cancelled.');
        await pool.end();
        process.exit(0);
      }
      console.log('');
    }

    // Delete all restaurants and menus
    await deleteAllRestaurants();

    // Get final counts
    console.log('\nVerifying deletion...');
    const finalCounts = await getCounts();
    console.log(`  Restaurants: ${finalCounts.restaurants}`);
    console.log(`  Menu Categories: ${finalCounts.menuCategories}`);
    console.log(`  Menu Items: ${finalCounts.menuItems}`);
    console.log(`  Orders: ${finalCounts.orders}`);
    console.log(`  Order Items: ${finalCounts.orderItems}`);

  } catch (error) {
    console.error('\n✗ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run the script
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
