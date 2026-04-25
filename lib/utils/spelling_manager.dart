/// SpellingManager manages text input for spelling mode functionality
/// Handles letter addition, deletion, and clearing for the app's spelling feature

class SpellingManager {
  /// The current spelled text
  String _currentText = '';

  /// Get the current spelled string
  String get currentText => _currentText;

  /// Get the length of current text
  int get length => _currentText.length;

  /// Check if text is empty
  bool get isEmpty => _currentText.isEmpty;

  /// Adds a letter to the end of the current text
  ///
  /// Parameters:
  /// - [letter]: Single character or string to append
  ///
  /// Returns: The updated text after adding the letter
  ///
  /// Example:
  /// ```
  /// manager.addLetter('A');
  /// manager.currentText; // 'A'
  /// manager.addLetter('B');
  /// manager.currentText; // 'AB'
  /// ```
  String addLetter(String letter) {
    if (letter.isEmpty) {
      throw ArgumentError('Letter cannot be empty');
    }

    _currentText += letter;
    return _currentText;
  }

  /// Deletes the last character from the current text
  ///
  /// Returns: The updated text after deletion, or empty string if already empty
  ///
  /// Example:
  /// ```
  /// manager.addLetter('A');
  /// manager.addLetter('B');
  /// manager.currentText; // 'AB'
  /// manager.deleteLastLetter();
  /// manager.currentText; // 'A'
  /// manager.deleteLastLetter();
  /// manager.currentText; // ''
  /// manager.deleteLastLetter(); // Safe: returns ''
  /// manager.currentText; // ''
  /// ```
  String deleteLastLetter() {
    if (_currentText.isNotEmpty) {
      _currentText = _currentText.substring(0, _currentText.length - 1);
    }
    return _currentText;
  }

  /// Clears all text and resets to empty string
  ///
  /// Returns: Empty string
  ///
  /// Example:
  /// ```
  /// manager.addLetter('H');
  /// manager.addLetter('I');
  /// manager.currentText; // 'HI'
  /// manager.clearAll();
  /// manager.currentText; // ''
  /// ```
  String clearAll() {
    _currentText = '';
    return _currentText;
  }

  /// Adds multiple letters at once
  ///
  /// Parameters:
  /// - [letters]: String of multiple characters to append
  ///
  /// Returns: The updated text after adding all letters
  String addLetters(String letters) {
    if (letters.isEmpty) {
      throw ArgumentError('Letters string cannot be empty');
    }

    _currentText += letters;
    return _currentText;
  }

  /// Replaces the entire current text with new text
  ///
  /// Parameters:
  /// - [newText]: The new text to set
  ///
  /// Returns: The new text
  String replaceText(String newText) {
    _currentText = newText;
    return _currentText;
  }

  /// Gets the character at the specified index
  ///
  /// Parameters:
  /// - [index]: The index of the character
  ///
  /// Returns: Character at the index
  /// 
  /// Throws: [RangeError] if index is out of bounds
  String getCharAt(int index) {
    return _currentText[index];
  }

  /// Removes a character at the specified index
  ///
  /// Parameters:
  /// - [index]: The index of the character to remove
  ///
  /// Returns: The updated text after removal
  ///
  /// Throws: [RangeError] if index is out of bounds
  String removeCharAt(int index) {
    if (index < 0 || index >= _currentText.length) {
      throw RangeError('Index $index out of range for text of length ${_currentText.length}');
    }

    _currentText = _currentText.substring(0, index) + _currentText.substring(index + 1);
    return _currentText;
  }

  /// Resets the manager to initial state (empty text)
  void reset() {
    _currentText = '';
  }

  @override
  String toString() => 'SpellingManager(text: "$_currentText", length: ${_currentText.length})';
}
