/// Unit tests for SpellingManager class
/// Tests letter addition, deletion, and clearing functionality for spelling mode

import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/utils/spelling_manager.dart';

void main() {
  group('SpellingManager Tests', () {
    late SpellingManager manager;

    setUp(() {
      // Create fresh manager for each test
      manager = SpellingManager();
    });

    group('addLetter', () {
      test('should add single letter to empty text', () {
        // Act
        manager.addLetter('A');

        // Assert
        expect(manager.currentText, equals('A'));
        expect(manager.length, equals(1));
      });

      test('should append letter to existing text', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('B');

        // Assert
        expect(manager.currentText, equals('AB'));
        expect(manager.length, equals(2));
      });

      test('should return updated text after adding letter', () {
        // Act
        final result = manager.addLetter('H');

        // Assert
        expect(result, equals('H'));
      });

      test('should add multiple different letters sequentially', () {
        // Act
        manager.addLetter('H');
        manager.addLetter('E');
        manager.addLetter('L');
        manager.addLetter('L');
        manager.addLetter('O');

        // Assert
        expect(manager.currentText, equals('HELLO'));
        expect(manager.length, equals(5));
      });

      test('should add lowercase letters', () {
        // Act
        manager.addLetter('a');
        manager.addLetter('b');
        manager.addLetter('c');

        // Assert
        expect(manager.currentText, equals('abc'));
      });

      test('should add numbers as strings', () {
        // Act
        manager.addLetter('1');
        manager.addLetter('2');
        manager.addLetter('3');

        // Assert
        expect(manager.currentText, equals('123'));
      });

      test('should add special characters', () {
        // Act
        manager.addLetter(' ');
        manager.addLetter('!');
        manager.addLetter('?');

        // Assert
        expect(manager.currentText, equals(' !?'));
      });

      test('should add multi-character string (not just single char)', () {
        // Act
        manager.addLetter('Hello');

        // Assert
        expect(manager.currentText, equals('Hello'));
        expect(manager.length, equals(5));
      });

      test('should throw error for empty string', () {
        // Act & Assert
        expect(
          () => manager.addLetter(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle rapid consecutive additions', () {
        // Act: add many letters quickly
        for (int i = 0; i < 100; i++) {
          manager.addLetter('A');
        }

        // Assert
        expect(manager.length, equals(100));
        expect(manager.currentText, equals('A' * 100));
      });

      test('should preserve case sensitivity', () {
        // Act
        manager.addLetter('A');
        manager.addLetter('a');
        manager.addLetter('B');
        manager.addLetter('b');

        // Assert
        expect(manager.currentText, equals('AaBb'));
      });

      test('should track length correctly after additions', () {
        // Arrange
        expect(manager.length, equals(0));

        // Act & Assert at each step
        manager.addLetter('X');
        expect(manager.length, equals(1));

        manager.addLetter('Y');
        expect(manager.length, equals(2));

        manager.addLetter('Z');
        expect(manager.length, equals(3));
      });
    });

    group('deleteLastLetter', () {
      test('should delete last letter from text', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('B');
        manager.addLetter('C');

        // Act
        manager.deleteLastLetter();

        // Assert
        expect(manager.currentText, equals('AB'));
        expect(manager.length, equals(2));
      });

      test('should return updated text after deletion', () {
        // Arrange
        manager.addLetter('H');
        manager.addLetter('I');

        // Act
        final result = manager.deleteLastLetter();

        // Assert
        expect(result, equals('H'));
      });

      test('should delete single letter leaving empty string', () {
        // Arrange
        manager.addLetter('A');

        // Act
        manager.deleteLastLetter();

        // Assert
        expect(manager.currentText, isEmpty);
        expect(manager.length, equals(0));
      });

      test('should handle deletion on empty text safely', () {
        // Arrange: text is empty
        expect(manager.isEmpty, isTrue);

        // Act: delete from empty should not error
        manager.deleteLastLetter();

        // Assert: should remain empty
        expect(manager.currentText, isEmpty);
        expect(manager.length, equals(0));
      });

      test('should delete multiple times correctly', () {
        // Arrange: build text
        manager.addLetter('H');
        manager.addLetter('E');
        manager.addLetter('L');
        manager.addLetter('L');
        manager.addLetter('O');

        // Act & Assert at each deletion
        manager.deleteLastLetter();
        expect(manager.currentText, equals('HELL'));

        manager.deleteLastLetter();
        expect(manager.currentText, equals('HEL'));

        manager.deleteLastLetter();
        expect(manager.currentText, equals('HE'));

        manager.deleteLastLetter();
        expect(manager.currentText, equals('H'));

        manager.deleteLastLetter();
        expect(manager.currentText, isEmpty);
      });

      test('should delete multi-character strings added as single addition', () {
        // Arrange
        manager.addLetter('WORD');

        // Act: delete once should remove entire 'WORD'? 
        // Actually, it removes one character from the end
        manager.deleteLastLetter();

        // Assert
        expect(manager.currentText, equals('WOR'));
      });

      test('should handle deletion of special characters', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('!');
        manager.addLetter('B');

        // Act
        manager.deleteLastLetter();

        // Assert: should remove 'B', leaving 'A!'
        expect(manager.currentText, equals('A!'));
      });

      test('should maintain length after deletions', () {
        // Arrange
        manager.addLetters('ABCDE');
        expect(manager.length, equals(5));

        // Act & Assert
        manager.deleteLastLetter();
        expect(manager.length, equals(4));

        manager.deleteLastLetter();
        expect(manager.length, equals(3));
      });

      test('should repeatedly call delete on empty without error', () {
        // Arrange: empty manager
        expect(manager.isEmpty, isTrue);

        // Act: multiple deletes on empty
        manager.deleteLastLetter();
        manager.deleteLastLetter();
        manager.deleteLastLetter();

        // Assert: should remain empty and safe
        expect(manager.currentText, isEmpty);
      });

      test('should delete backspace functionality correctly', () {
        // Arrange: simulate backspace in spelling app
        manager.addLetter('C');
        manager.addLetter('A');
        manager.addLetter('T');

        // Act: user presses backspace
        manager.deleteLastLetter(); // Remove 'T'

        // Assert
        expect(manager.currentText, equals('CA'));
      });
    });

    group('clearAll', () {
      test('should clear all text and return empty string', () {
        // Arrange: add some text
        manager.addLetter('A');
        manager.addLetter('B');
        manager.addLetter('C');

        // Act
        final result = manager.clearAll();

        // Assert
        expect(result, isEmpty);
        expect(manager.currentText, isEmpty);
        expect(manager.length, equals(0));
      });

      test('should work on empty text without error', () {
        // Arrange: already empty
        expect(manager.isEmpty, isTrue);

        // Act
        manager.clearAll();

        // Assert
        expect(manager.currentText, isEmpty);
      });

      test('should reset after building large text', () {
        // Arrange: add many letters
        for (int i = 0; i < 50; i++) {
          manager.addLetter('X');
        }
        expect(manager.length, equals(50));

        // Act
        manager.clearAll();

        // Assert
        expect(manager.currentText, isEmpty);
        expect(manager.length, equals(0));
      });

      test('should allow new additions after clearing', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('B');
        manager.clearAll();

        // Act: add new text
        manager.addLetter('C');
        manager.addLetter('D');

        // Assert
        expect(manager.currentText, equals('CD'));
      });

      test('should work multiple times', () {
        // Arrange & Act
        manager.addLetter('X');
        manager.clearAll();
        expect(manager.isEmpty, isTrue);

        manager.addLetter('Y');
        manager.clearAll();
        expect(manager.isEmpty, isTrue);

        manager.addLetter('Z');
        manager.clearAll();

        // Assert
        expect(manager.isEmpty, isTrue);
      });

      test('should clear text with special characters', () {
        // Arrange
        manager.addLetter('!');
        manager.addLetter('@');
        manager.addLetter('#');

        // Act
        manager.clearAll();

        // Assert
        expect(manager.currentText, isEmpty);
      });

      test('should reset state completely for spelling app', () {
        // Arrange: simulate full spelling flow
        manager.addLetter('H');
        manager.addLetter('E');
        manager.addLetter('L');
        manager.addLetter('L');
        manager.addLetter('O');

        // Act: user starts new word
        manager.clearAll();

        // Assert: ready for new word
        expect(manager.currentText, isEmpty);
        expect(manager.length, equals(0));
        expect(manager.isEmpty, isTrue);

        // Act: add new word
        manager.addLetter('W');
        manager.addLetter('O');
        manager.addLetter('W');

        // Assert: new word is correct
        expect(manager.currentText, equals('WOW'));
      });
    });

    group('isEmpty and length properties', () {
      test('should report isEmpty as true when empty', () {
        // Assert
        expect(manager.isEmpty, isTrue);
      });

      test('should report isEmpty as false when has content', () {
        // Arrange
        manager.addLetter('A');

        // Assert
        expect(manager.isEmpty, isFalse);
      });

      test('should report correct length', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('B');
        manager.addLetter('C');

        // Assert
        expect(manager.length, equals(3));
      });

      test('should update length after operations', () {
        // Arrange
        expect(manager.length, equals(0));

        // Act
        manager.addLetter('X');
        expect(manager.length, equals(1));

        manager.addLetter('Y');
        expect(manager.length, equals(2));

        manager.deleteLastLetter();
        expect(manager.length, equals(1));

        manager.clearAll();
        expect(manager.length, equals(0));
      });
    });

    group('Additional functionality tests', () {
      test('addLetters should add multiple letters at once', () {
        // Act
        manager.addLetters('HELLO');

        // Assert
        expect(manager.currentText, equals('HELLO'));
        expect(manager.length, equals(5));
      });

      test('addLetters should throw error for empty string', () {
        // Act & Assert
        expect(
          () => manager.addLetters(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('replaceText should replace entire text', () {
        // Arrange
        manager.addLetter('A');
        manager.addLetter('B');

        // Act
        manager.replaceText('XYZ');

        // Assert
        expect(manager.currentText, equals('XYZ'));
      });

      test('getCharAt should return character at index', () {
        // Arrange
        manager.addLetters('HELLO');

        // Assert
        expect(manager.getCharAt(0), equals('H'));
        expect(manager.getCharAt(2), equals('L'));
        expect(manager.getCharAt(4), equals('O'));
      });

      test('getCharAt should throw for out of bounds index', () {
        // Arrange
        manager.addLetters('HI');

        // Act & Assert
        expect(
          () => manager.getCharAt(5),
          throwsA(isA<RangeError>()),
        );
      });

      test('removeCharAt should remove character at specific index', () {
        // Arrange
        manager.addLetters('HELLO');

        // Act: remove 'L' at index 2
        manager.removeCharAt(2);

        // Assert
        expect(manager.currentText, equals('HELO'));
      });

      test('toString should provide readable representation', () {
        // Arrange
        manager.addLetters('TEST');

        // Act
        final str = manager.toString();

        // Assert
        expect(str, contains('TEST'));
        expect(str, contains('4')); // length
      });

      test('reset should clear all text', () {
        // Arrange
        manager.addLetters('SOMETHING');

        // Act
        manager.reset();

        // Assert
        expect(manager.isEmpty, isTrue);
        expect(manager.currentText, isEmpty);
      });
    });

    group('Integration tests', () {
      test('should handle complete spelling workflow', () {
        // Arrange: simulate user spelling a word
        expect(manager.currentText, isEmpty);

        // Act: spell 'FLUTTER'
        manager.addLetter('F');
        expect(manager.currentText, equals('F'));

        manager.addLetter('L');
        expect(manager.currentText, equals('FL'));

        manager.addLetter('U');
        expect(manager.currentText, equals('FLU'));

        // User makes mistake - delete and correct
        manager.deleteLastLetter(); // Remove 'U'
        expect(manager.currentText, equals('FL'));

        manager.addLetter('U');
        manager.addLetter('T');
        manager.addLetter('T');
        manager.addLetter('E');
        manager.addLetter('R');

        // Assert: final word is correct
        expect(manager.currentText, equals('FLUTTER'));
      });

      test('should handle user corrections during spelling', () {
        // Arrange
        manager.addLetters('CAT');

        // Act: delete and retype
        manager.deleteLastLetter(); // Remove 'T'
        manager.deleteLastLetter(); // Remove 'A'
        manager.addLetters('AR');

        // Assert
        expect(manager.currentText, equals('CAR'));
      });

      test('should handle switching between words', () {
        // Arrange: first word
        manager.addLetters('FIRST');
        expect(manager.currentText, equals('FIRST'));

        // Act: clear for new word
        manager.clearAll();
        manager.addLetters('SECOND');

        // Assert
        expect(manager.currentText, equals('SECOND'));
      });
    });
  });
}
