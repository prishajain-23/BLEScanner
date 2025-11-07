#!/usr/bin/env node

/**
 * Database Connection Test Script
 * Tests PostgreSQL connection and verifies schema
 */

const { pool, testConnection } = require('./config/database');

async function runTests() {
  console.log('\n🔍 Testing BLEScanner Database Connection...\n');

  try {
    // Test 1: Basic connection
    console.log('Test 1: Testing database connection...');
    const connected = await testConnection();
    if (!connected) {
      console.error('❌ Failed to connect to database');
      process.exit(1);
    }

    // Test 2: Verify tables exist
    console.log('\nTest 2: Verifying database schema...');
    const tableQuery = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `;
    const tablesResult = await pool.query(tableQuery);
    const tables = tablesResult.rows.map(row => row.table_name);

    const expectedTables = ['users', 'messages', 'message_recipients', 'contacts'];
    const missingTables = expectedTables.filter(t => !tables.includes(t));

    if (missingTables.length > 0) {
      console.error(`❌ Missing tables: ${missingTables.join(', ')}`);
      console.log('   Run: psql -U blescanner_user -d blescanner -f db/schema.sql');
      process.exit(1);
    }

    console.log(`✅ All tables exist: ${tables.join(', ')}`);

    // Test 3: Check indexes
    console.log('\nTest 3: Checking indexes...');
    const indexQuery = `
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'public'
      AND indexname LIKE 'idx_%'
      ORDER BY indexname;
    `;
    const indexResult = await pool.query(indexQuery);
    const indexes = indexResult.rows.map(row => row.indexname);
    console.log(`✅ Found ${indexes.length} custom indexes`);
    indexes.forEach(idx => console.log(`   - ${idx}`));

    // Test 4: Test basic query
    console.log('\nTest 4: Testing basic queries...');
    const countQuery = 'SELECT COUNT(*) as count FROM users';
    const countResult = await pool.query(countQuery);
    console.log(`✅ Users table query successful (${countResult.rows[0].count} users)`);

    // Success summary
    console.log('\n' + '='.repeat(50));
    console.log('✅ ALL TESTS PASSED!');
    console.log('='.repeat(50));
    console.log('\nDatabase is ready for development.');
    console.log('Next step: Run `npm run dev` to start the server\n');

  } catch (error) {
    console.error('\n❌ TEST FAILED:');
    console.error(error.message);
    console.error('\nTroubleshooting:');
    console.error('1. Check PostgreSQL is running: brew services list');
    console.error('2. Verify .env file has correct credentials');
    console.error('3. Ensure database exists: psql -l');
    console.error('4. Run schema: psql -U blescanner_user -d blescanner -f db/schema.sql\n');
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run tests
runTests();
