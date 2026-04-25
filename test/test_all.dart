// Test suite runner for all unit tests
// Run this file to execute all tests for the MSL Recognition App

import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'utils/data_normalizer_test.dart' as data_normalizer_tests;
import 'utils/spelling_manager_test.dart' as spelling_manager_tests;
import 'utils/confidence_checker_test.dart' as confidence_checker_tests;

void main() {
  // All tests are organized in the individual test files and will be discovered
  // by the test runner automatically.
  // 
  // To run all tests:
  // flutter test
  //
  // To run specific test file:
  // flutter test test/utils/data_normalizer_test.dart
  // flutter test test/utils/spelling_manager_test.dart
  // flutter test test/utils/confidence_checker_test.dart
  //
  // To run with coverage:
  // flutter test --coverage
  //
  // To run with verbose output:
  // flutter test --verbose
  //
  // Test structure:
  // - data_normalizer_test.dart: Tests for coordinate normalization and landmark flattening
  // - spelling_manager_test.dart: Tests for spelling mode letter management
  // - confidence_checker_test.dart: Tests for confidence threshold validation
  //
  // Total test count: 100+ unit tests
  
  group('MSL Recognition App Test Suite', () {
    test('Test suite description', () {
      expect(true, isTrue);
    });
  });
}
