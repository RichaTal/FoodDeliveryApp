# Test Coverage Guide

This document explains how to check unit test coverage for the entire codebase.

## Quick Start

### Run Coverage for All Services

```bash
npm run test:coverage
```

This will:
- Run test coverage for all services
- Generate individual coverage reports for each service
- Create an aggregated coverage summary
- Display coverage statistics in the terminal

### Run Coverage for Individual Services

```bash
# Restaurant Menu Service
npm run test:coverage:restaurant-menu

# Order Service
npm run test:coverage:order

# Driver Location Service
npm run test:coverage:driver-location

# Notification Service
npm run test:coverage:notification
```

Or navigate to the service directory and run:

```bash
cd services/<service-name>
npm run test:coverage
```

## Coverage Reports

### Individual Service Reports

Each service generates coverage reports in its own `coverage` directory:

- `services/restaurant-menu-service/coverage/`
- `services/order-service/coverage/`
- `services/driver-location-service/coverage/`
- `services/notification-service/coverage/`

### Aggregated Coverage Report

When running `npm run test:coverage`, an aggregated summary is created at:

- `coverage/coverage-summary.json` - JSON summary of all services
- `coverage/<service-name>-coverage.html` - HTML reports for each service

### Viewing HTML Reports

Open the HTML reports in your browser:

```bash
# Individual service reports
open services/restaurant-menu-service/coverage/index.html
open services/order-service/coverage/index.html
open services/driver-location-service/coverage/index.html
open services/notification-service/coverage/index.html

# Aggregated reports (after running npm run test:coverage)
open coverage/restaurant-menu-service-coverage.html
open coverage/order-service-coverage.html
open coverage/driver-location-service-coverage.html
open coverage/notification-service-coverage.html
```

## Coverage Configuration

Coverage is configured in each service's `jest.config.cjs` file:

- **Collects coverage from**: `src/**/*.ts` (excluding test files and index.ts)
- **Coverage reporters**: text, text-summary, html, lcov, json
- **Coverage directory**: `coverage/`

### Coverage Thresholds

Currently, coverage thresholds are set to 0% (no enforcement). You can update thresholds in each service's `jest.config.cjs`:

```javascript
coverageThreshold: {
  global: {
    branches: 80,    // Require 80% branch coverage
    functions: 80,   // Require 80% function coverage
    lines: 80,       // Require 80% line coverage
    statements: 80,  // Require 80% statement coverage
  },
},
```

## Coverage Metrics Explained

- **Statements**: Percentage of code statements executed
- **Branches**: Percentage of conditional branches executed (if/else, switch cases)
- **Functions**: Percentage of functions called
- **Lines**: Percentage of lines executed

## CI/CD Integration

To integrate coverage reporting in CI/CD pipelines:

```bash
# Generate coverage reports
npm run test:coverage

# Coverage reports will be available at:
# - Individual: services/*/coverage/lcov.info (for Codecov, Coveralls, etc.)
# - Aggregated: coverage/coverage-summary.json
```

## Troubleshooting

### Coverage Not Generating

1. Ensure tests are passing: `npm test`
2. Check that `jest.config.cjs` includes coverage configuration
3. Verify `collectCoverageFrom` paths are correct

### Coverage Shows 0%

- Ensure source files are in `src/` directory
- Check that files match the `collectCoverageFrom` patterns
- Verify tests are actually executing code (not just mocking everything)

### Missing Service Coverage

- Ensure the service has a `jest.config.cjs` file
- Verify the service has a `test:coverage` script in `package.json`
- Check that the service name matches in `scripts/coverage-all.js`

## Best Practices

1. **Run coverage regularly** during development
2. **Aim for meaningful coverage** - focus on critical business logic
3. **Review uncovered code** to identify gaps in testing
4. **Set realistic thresholds** - 100% coverage isn't always practical
5. **Use coverage to guide testing** - identify untested code paths
