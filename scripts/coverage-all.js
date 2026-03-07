#!/usr/bin/env node

/**
 * Script to run test coverage for all services and aggregate results
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const services = [
  'restaurant-menu-service',
  'order-service',
  'driver-location-service',
  'notification-service',
];

const rootDir = path.resolve(__dirname, '..');
const coverageDir = path.join(rootDir, 'coverage');

console.log('🧪 Running test coverage for all services...\n');

// Clean previous coverage directory
if (fs.existsSync(coverageDir)) {
  fs.rmSync(coverageDir, { recursive: true, force: true });
}
fs.mkdirSync(coverageDir, { recursive: true });

let totalStats = {
  statements: { total: 0, covered: 0 },
  branches: { total: 0, covered: 0 },
  functions: { total: 0, covered: 0 },
  lines: { total: 0, covered: 0 },
};

const serviceStats = {};

// Run coverage for each service
services.forEach((service) => {
  const servicePath = path.join(rootDir, 'services', service);
  
  if (!fs.existsSync(servicePath)) {
    console.log(`⚠️  Skipping ${service} - directory not found`);
    return;
  }

  console.log(`\n📦 Running coverage for ${service}...`);
  
  try {
    // Run coverage
    execSync('npm run test:coverage', {
      cwd: servicePath,
      stdio: 'inherit',
    });

    // Read coverage summary
    const coverageSummaryPath = path.join(servicePath, 'coverage', 'coverage-summary.json');
    const coverageFinalPath = path.join(servicePath, 'coverage', 'coverage-final.json');
    
    let coverageData = null;
    let totals = {};
    
    if (fs.existsSync(coverageSummaryPath)) {
      try {
        coverageData = JSON.parse(fs.readFileSync(coverageSummaryPath, 'utf8'));
        totals = coverageData.total || {};
      } catch (error) {
        console.error(`⚠️  Error reading coverage-summary.json for ${service}:`, error.message);
      }
    } else if (fs.existsSync(coverageFinalPath)) {
      // Fallback: calculate totals from coverage-final.json
      console.log(`⚠️  coverage-summary.json not found for ${service}, calculating from coverage-final.json...`);
      try {
        const finalData = JSON.parse(fs.readFileSync(coverageFinalPath, 'utf8'));
        totals = calculateTotalsFromFinal(finalData);
      } catch (error) {
        console.error(`⚠️  Error reading coverage-final.json for ${service}:`, error.message);
      }
    } else {
      console.log(`⚠️  No coverage files found for ${service} in ${path.join(servicePath, 'coverage')}`);
    }
    
    if (totals.statements || totals.branches || totals.functions || totals.lines) {
      const serviceStatements = totals.statements || { total: 0, covered: 0 };
      const serviceBranches = totals.branches || { total: 0, covered: 0 };
      const serviceFunctions = totals.functions || { total: 0, covered: 0 };
      const serviceLines = totals.lines || { total: 0, covered: 0 };

      serviceStats[service] = {
        statements: {
          ...serviceStatements,
          skipped: 0,
          pct: parseFloat(calculatePercentage(serviceStatements.covered, serviceStatements.total)),
        },
        branches: {
          ...serviceBranches,
          skipped: 0,
          pct: parseFloat(calculatePercentage(serviceBranches.covered, serviceBranches.total)),
        },
        functions: {
          ...serviceFunctions,
          skipped: 0,
          pct: parseFloat(calculatePercentage(serviceFunctions.covered, serviceFunctions.total)),
        },
        lines: {
          ...serviceLines,
          skipped: 0,
          pct: parseFloat(calculatePercentage(serviceLines.covered, serviceLines.total)),
        },
      };

      // Aggregate totals
      ['statements', 'branches', 'functions', 'lines'].forEach((key) => {
        if (totals[key]) {
          totalStats[key].total += totals[key].total || 0;
          totalStats[key].covered += totals[key].covered || 0;
        }
      });

      // Copy HTML coverage report
      const serviceCoverageHtml = path.join(servicePath, 'coverage', 'index.html');
      const aggregatedCoverageHtml = path.join(coverageDir, `${service}-coverage.html`);
      if (fs.existsSync(serviceCoverageHtml)) {
        fs.copyFileSync(serviceCoverageHtml, aggregatedCoverageHtml);
      }
    } else {
      console.log(`⚠️  No coverage data found for ${service}`);
    }
  } catch (error) {
    console.error(`❌ Error running coverage for ${service}:`, error.message);
  }
});

// Calculate totals from coverage-final.json format
function calculateTotalsFromFinal(finalData) {
  let totals = {
    statements: { total: 0, covered: 0 },
    branches: { total: 0, covered: 0 },
    functions: { total: 0, covered: 0 },
    lines: { total: 0, covered: 0 },
  };

  Object.values(finalData).forEach((fileData) => {
    if (fileData.s) {
      // Statements
      totals.statements.total += Object.keys(fileData.s).length;
      totals.statements.covered += Object.values(fileData.s).filter(count => count > 0).length;
    }
    if (fileData.f) {
      // Functions
      totals.functions.total += Object.keys(fileData.f).length;
      totals.functions.covered += Object.values(fileData.f).filter(count => count > 0).length;
    }
    if (fileData.b) {
      // Branches
      Object.values(fileData.b).forEach((branchCounts) => {
        totals.branches.total += branchCounts.length;
        totals.branches.covered += branchCounts.filter(count => count > 0).length;
      });
    }
    if (fileData.statementMap) {
      // Lines (approximate from statements)
      totals.lines.total += Object.keys(fileData.statementMap).length;
      totals.lines.covered += Object.keys(fileData.s || {}).filter(key => fileData.s[key] > 0).length;
    }
  });

  return totals;
}

// Calculate percentages
function calculatePercentage(covered, total) {
  if (total === 0) return '0.00';
  return ((covered / total) * 100).toFixed(2);
}

// Print summary
console.log('\n' + '='.repeat(80));
console.log('📊 COVERAGE SUMMARY');
console.log('='.repeat(80));

services.forEach((service) => {
  if (serviceStats[service]) {
    const stats = serviceStats[service];
    console.log(`\n📦 ${service}:`);
    console.log(`   Statements: ${calculatePercentage(stats.statements.covered, stats.statements.total)}% (${stats.statements.covered}/${stats.statements.total})`);
    console.log(`   Branches:   ${calculatePercentage(stats.branches.covered, stats.branches.total)}% (${stats.branches.covered}/${stats.branches.total})`);
    console.log(`   Functions:  ${calculatePercentage(stats.functions.covered, stats.functions.total)}% (${stats.functions.covered}/${stats.functions.total})`);
    console.log(`   Lines:      ${calculatePercentage(stats.lines.covered, stats.lines.total)}% (${stats.lines.covered}/${stats.lines.total})`);
  }
});

console.log('\n' + '-'.repeat(80));
console.log('📊 OVERALL COVERAGE:');
console.log('-'.repeat(80));
console.log(`   Statements: ${calculatePercentage(totalStats.statements.covered, totalStats.statements.total)}% (${totalStats.statements.covered}/${totalStats.statements.total})`);
console.log(`   Branches:   ${calculatePercentage(totalStats.branches.covered, totalStats.branches.total)}% (${totalStats.branches.covered}/${totalStats.branches.total})`);
console.log(`   Functions:  ${calculatePercentage(totalStats.functions.covered, totalStats.functions.total)}% (${totalStats.functions.covered}/${totalStats.functions.total})`);
console.log(`   Lines:      ${calculatePercentage(totalStats.lines.covered, totalStats.lines.total)}% (${totalStats.lines.covered}/${totalStats.lines.total})`);
console.log('='.repeat(80));

// Save aggregated coverage summary with overall totals
// The "total" section contains aggregated coverage across all services
// Each service section contains individual service coverage
const aggregatedSummary = {
  total: {
    statements: {
      total: totalStats.statements.total,
      covered: totalStats.statements.covered,
      skipped: 0,
      pct: parseFloat(calculatePercentage(totalStats.statements.covered, totalStats.statements.total)),
    },
    branches: {
      total: totalStats.branches.total,
      covered: totalStats.branches.covered,
      skipped: 0,
      pct: parseFloat(calculatePercentage(totalStats.branches.covered, totalStats.branches.total)),
    },
    functions: {
      total: totalStats.functions.total,
      covered: totalStats.functions.covered,
      skipped: 0,
      pct: parseFloat(calculatePercentage(totalStats.functions.covered, totalStats.functions.total)),
    },
    lines: {
      total: totalStats.lines.total,
      covered: totalStats.lines.covered,
      skipped: 0,
      pct: parseFloat(calculatePercentage(totalStats.lines.covered, totalStats.lines.total)),
    },
  },
  ...serviceStats,
};

fs.writeFileSync(
  path.join(coverageDir, 'coverage-summary.json'),
  JSON.stringify(aggregatedSummary, null, 2)
);

console.log(`\n✅ Coverage reports saved to: ${coverageDir}`);
console.log(`📄 View individual service coverage:`);
services.forEach((service) => {
  console.log(`   - ${service}: services/${service}/coverage/index.html`);
});
console.log(`\n📄 Aggregated summary: coverage/coverage-summary.json`);
