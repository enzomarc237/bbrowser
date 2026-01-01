# BBrowser Test Suite

This directory contains the comprehensive test suite for BBrowser, implementing Test-Driven Development (TDD) practices with >80% code coverage requirement.

## Directory Structure

```
test/
├── unit/                    # Unit tests for isolated components
│   ├── models/             # Model tests (Tab, etc.)
│   ├── blocs/              # BLoC state management tests
│   ├── services/           # Service layer tests
│   └── repositories/       # Repository pattern tests
├── widget/                 # Widget/UI component tests
│   ├── screens/            # Screen-level widget tests
│   └── widgets/            # Individual widget component tests
├── integration/            # End-to-end workflow tests
├── performance/            # Performance benchmarks and regression tests
├── helpers/                # Custom matchers and assertion helpers
├── fixtures/               # Test data factories and mock objects
└── utils/                  # Test utilities and common functions
```

## Test Categories

### Unit Tests (`test/unit/`)
- **Models**: Test data models for serialization, equality, validation
- **BLoCs**: Test state management logic, event handling, state transitions
- **Services**: Test business logic, API interactions, data processing
- **Repositories**: Test data access patterns, CRUD operations

### Widget Tests (`test/widget/`)
- **Screens**: Test complete screen layouts and interactions
- **Widgets**: Test individual UI components and their behavior

### Integration Tests (`test/integration/`)
- End-to-end user workflows
- Cross-component communication
- Database integration
- Performance under load

### Performance Tests (`test/performance/`)
- Tab switching performance
- Memory usage benchmarks
- UI rendering performance
- Load testing scenarios

## Running Tests

### All Tests
```bash
flutter test
```

### Unit Tests Only
```bash
flutter test test/unit/
```

### Widget Tests Only
```bash
flutter test test/widget/
```

### Integration Tests Only
```bash
flutter test test/integration/
```

### Performance Tests
```bash
flutter test test/performance/
```

### Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Data Management

### Mock Data Factories
- Use builder pattern for flexible test data creation
- Located in `test/fixtures/entity_builders.dart`
- Provides fluent API for creating test entities

### Scenario Data
- Pre-built test scenarios for common workflows
- Located in `test/fixtures/scenario_data.dart`
- Includes edge cases and performance testing data

### Test Utilities
- Custom matchers and assertion helpers
- Common test setup and teardown functions
- Mock object factories and utilities

## Coverage Requirements

- **Minimum Coverage**: 80% overall
- **Unit Tests**: 90% coverage target
- **Widget Tests**: 85% coverage target
- **Integration Tests**: 70% coverage target

## Quality Gates

### Pre-commit
- All unit tests pass
- Code coverage >80%
- No linting errors
- Static analysis passes

### Pre-merge
- All widget tests pass
- Integration tests pass
- Performance benchmarks met
- Documentation updated

### Pre-release
- All E2E tests pass
- Performance validation complete
- Security scanning passes

## Best Practices

1. **Test Naming**: Use descriptive test names that explain the scenario
2. **Test Structure**: Follow Arrange-Act-Assert pattern
3. **Mock Strategy**: Mock at appropriate abstraction levels
4. **Test Data**: Use builders for flexible test data creation
5. **Assertions**: Use specific matchers for clear failure messages
6. **Performance**: Keep unit tests fast (<30s total execution)
7. **Isolation**: Ensure tests are independent and can run in any order

## Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure >80% coverage for new code
3. Add appropriate test data to fixtures
4. Update documentation as needed
5. Verify all quality gates pass

## Tools and Dependencies

- **flutter_test**: Core Flutter testing framework
- **bloc_test**: BLoC testing utilities
- **mocktail**: Mocking framework
- **build_runner**: Code generation for test utilities

## Continuous Integration

Tests run automatically on:
- Pull request creation
- Push to main branch
- Scheduled nightly runs

See `.github/workflows/` for CI/CD configuration.
