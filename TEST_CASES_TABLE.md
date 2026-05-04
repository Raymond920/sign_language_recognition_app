# Unit Test Cases - MSL Recognition App

## Data Normalizer Tests (DN)

| Unit Test Case ID | Test Case Description | Test Procedure | Test Data | Expected Result | Status |
|---|---|---|---|---|---|
| DN01 | Normalize midpoint coordinate | Call normalizeLandmarkCoordinate(540, 1080) | value: 540, screenDimension: 1080 | Result equals 0.5 | Pass |
| DN02 | Normalize zero value | Call normalizeLandmarkCoordinate(0, 1080) | value: 0, screenDimension: 1080 | Result equals 0.0 | Pass |
| DN03 | Clamp value at screen dimension | Call normalizeLandmarkCoordinate(1080, 1080) | value: 1080, screenDimension: 1080 | Result equals 1.0 | Pass |
| DN04 | Clamp values beyond screen dimension | Call normalizeLandmarkCoordinate(1500, 1080) | value: 1500 (beyond screen), screenDimension: 1080 | Result equals 1.0 | Pass |
| DN05 | Normalize quarter point | Call normalizeLandmarkCoordinate(270, 1080) | value: 270, screenDimension: 1080 | Result equals 0.25 | Pass |
| DN06 | Normalize three-quarter point | Call normalizeLandmarkCoordinate(810, 1080) | value: 810, screenDimension: 1080 | Result equals 0.75 | Pass |
| DN07 | Handle small screen dimensions | Call normalizeLandmarkCoordinate(25, 100) | value: 25, screenDimension: 100 | Result equals 0.25 | Pass |
| DN08 | Handle large screen dimensions | Call normalizeLandmarkCoordinate(960, 1920) | value: 960, screenDimension: 1920 | Result equals 0.5 | Pass |
| DN09 | Clamp negative values | Call normalizeLandmarkCoordinate(-100, 1080) | value: -100, screenDimension: 1080 | Result equals 0.0 | Pass |
| DN10 | Handle fractional coordinate values | Call normalizeLandmarkCoordinate(540.5, 1080) | value: 540.5, screenDimension: 1080 | Result > 0.49 and < 0.51 | Pass |
| DN11 | Create landmark with coordinates | Create LandmarkPoint(x: 0.5, y: 0.6, z: 0.7) | x: 0.5, y: 0.6, z: 0.7 | point.x equals 0.5, point.y equals 0.6, point.z equals 0.7 | Pass |
| DN12 | Support equality operator for landmarks | Create two identical LandmarkPoints and one different | point1: (0.5, 0.6, 0.7), point2: (0.5, 0.6, 0.7), point3: (0.5, 0.6, 0.8) | point1 equals point2, point1 not equals point3 | Pass |
| DN13 | Flatten 21 landmarks to 63 elements | Generate 21 landmarks and call flattenLandmarks | 21 LandmarkPoints(x: 0.1, y: 0.2, z: 0.3) | Flattened array length equals 63 | Pass |
| DN14 | Preserve coordinate order in flattening | Create 3 specific landmarks, pad to 21, then flatten | landmarks: (0.1,0.2,0.3), (0.4,0.5,0.6), (0.7,0.8,0.9) + 18 zeros | First landmark values: flattened[0]=0.1, flattened[1]=0.2, flattened[2]=0.3 | Pass |
| DN15 | Handle all zero coordinates | Generate 21 landmarks with (0.0, 0.0, 0.0) and flatten | 21 LandmarkPoints(x: 0.0, y: 0.0, z: 0.0) | All flattened values equal 0.0 | Pass |
| DN16 | Handle all one coordinates | Generate 21 landmarks with (1.0, 1.0, 1.0) and flatten | 21 LandmarkPoints(x: 1.0, y: 1.0, z: 1.0) | All flattened values equal 1.0 | Pass |
| DN17 | Handle decimal precision | Generate 21 landmarks with (0.333, 0.667, 0.999) and flatten | 21 LandmarkPoints(x: 0.333, y: 0.667, z: 0.999) | flattened[0] closeTo 0.333, flattened[1] closeTo 0.667, flattened[2] closeTo 0.999 | Pass |
| DN18 | Throw error if less than 21 landmarks | Create 20 landmarks and call flattenLandmarks | 20 LandmarkPoints | Throws ArgumentError | Pass |
| DN19 | Throw error if more than 21 landmarks | Create 22 landmarks and call flattenLandmarks | 22 LandmarkPoints | Throws ArgumentError | Pass |
| DN20 | Handle very small coordinate values | Generate 21 landmarks with (0.001, 0.001, 0.001) and flatten | 21 LandmarkPoints(x: 0.001, y: 0.001, z: 0.001) | flattened[0] closeTo 0.001 | Pass |
| DN21 | Handle very large coordinate values | Generate 21 landmarks with (1.5, 1.5, 1.5) and flatten | 21 LandmarkPoints(x: 1.5, y: 1.5, z: 1.5) | flattened[0] equals 1.5 | Pass |
| DN22 | Handle negative coordinate values | Generate 21 landmarks with alternating positive/negative | 21 LandmarkPoints with x: (index even ? 0.2 : -0.2) | flattened[0]=0.2, flattened[2]=0.2, flattened[3]=-0.2, flattened[5]=-0.2 | Pass |
| DN23 | Batch flatten landmarks correctly | Create 2 batches of 21 landmarks and batch flatten | batch1: 21 landmarks (0.1,0.2,0.3), batch2: 21 landmarks (0.4,0.5,0.6) | batchFlattened.length equals 2, each batch length equals 63 | Pass |
| DN24 | Handle empty batch | Call batchFlattenLandmarks([]) | Empty list | Result is empty list | Pass |
| DN25 | Handle single batch | Create 1 batch of 21 landmarks and batch flatten | 1 batch: 21 LandmarkPoints(x: 0.5, y: 0.5, z: 0.5) | result.length equals 1, result[0].length equals 63 | Pass |
| DN26 | Integration: normalize and flatten screen coordinates | Create landmarks at screen positions (0,0), (1920,0), (540,540) then normalize and flatten | Screen: 1080x1920, landmarks at various positions | Successfully flattened to 63 elements | Pass |

## Spelling Manager Tests (SM)

| Unit Test Case ID | Test Case Description | Test Procedure | Test Data | Expected Result | Status |
|---|---|---|---|---|---|
| SM01 | Add single letter to empty text | Create manager, add 'A' | manager: empty, letter: 'A' | currentText equals 'A', length equals 1 | Pass |
| SM02 | Append letter to existing text | Create manager, add 'A' then 'B' | manager: empty, letters: 'A', 'B' | currentText equals 'AB', length equals 2 | Pass |
| SM03 | Return updated text after adding letter | Create manager, add 'H' and return result | manager: empty, letter: 'H' | result equals 'H' | Pass |
| SM04 | Add multiple different letters sequentially | Create manager, add 'H','E','L','L','O' | manager: empty, letters: 'H','E','L','L','O' | currentText equals 'HELLO', length equals 5 | Pass |
| SM05 | Add lowercase letters | Create manager, add 'a','b','c' | manager: empty, letters: 'a','b','c' | currentText equals 'abc' | Pass |
| SM06 | Add numbers as strings | Create manager, add '1','2','3' | manager: empty, letters: '1','2','3' | currentText equals '123' | Pass |
| SM07 | Add special characters | Create manager, add ' ','!','?' | manager: empty, letters: ' ','!','?' | currentText equals ' !?' | Pass |
| SM08 | Add multi-character string | Create manager, add 'Hello' | manager: empty, text: 'Hello' | currentText equals 'Hello', length equals 5 | Pass |
| SM09 | Throw error for empty string in addLetter | Create manager, call addLetter('') | manager: empty, text: '' | Throws ArgumentError | Pass |
| SM10 | Handle rapid consecutive additions | Create manager, add 'A' 100 times | manager: empty, 100 additions of 'A' | length equals 100, currentText equals 'A'*100 | Pass |
| SM11 | Preserve case sensitivity | Create manager, add 'A','a','B','b' | manager: empty, letters: 'A','a','B','b' | currentText equals 'AaBb' | Pass |
| SM12 | Track length correctly after additions | Create manager, track length at each step | manager: empty, add 'X','Y','Z' | length: 0→1→2→3 | Pass |
| SM13 | Delete last letter from text | Create manager, add 'A','B','C', delete once | manager: 'ABC', delete once | currentText equals 'AB', length equals 2 | Pass |
| SM14 | Return updated text after deletion | Create manager, add 'H','I', delete and return | manager: 'HI', delete once | result equals 'H' | Pass |
| SM15 | Delete single letter leaving empty string | Create manager, add 'A', delete once | manager: 'A', delete once | currentText is empty, length equals 0 | Pass |
| SM16 | Handle deletion on empty text safely | Create manager, empty, delete | manager: empty, delete once | currentText remains empty, length equals 0 | Pass |
| SM17 | Delete multiple times correctly | Create manager, add 'HELLO', delete 5 times | manager: 'HELLO', delete 5 times | After each: 'HELL','HEL','HE','H','' | Pass |
| SM18 | Delete multi-character strings | Create manager, add 'WORD', delete once | manager: 'WORD', delete once | currentText equals 'WOR' | Pass |
| SM19 | Handle deletion of special characters | Create manager, add 'A','!','B', delete | manager: 'A!B', delete once | currentText equals 'A!' | Pass |
| SM20 | Maintain length after deletions | Create manager, add 'ABCDE', delete 2 times | manager: 'ABCDE', delete 2 times | length: 5→4→3 | Pass |
| SM21 | Repeatedly call delete on empty without error | Create manager, empty, delete 3 times | manager: empty, delete 3 times | currentText remains empty | Pass |
| SM22 | Delete backspace functionality correctly | Create manager, spell 'CAT', backspace once | manager: 'CAT', delete once (backspace) | currentText equals 'CA' | Pass |
| SM23 | Clear all text and return empty string | Create manager, add 'A','B','C', clear | manager: 'ABC', clearAll() | result is empty, currentText is empty, length equals 0 | Pass |
| SM24 | Work on empty text without error | Create manager, empty, clear | manager: empty, clearAll() | currentText remains empty | Pass |
| SM25 | Reset after building large text | Create manager, add 50 letters, clear | manager: 50 'X' letters, clearAll() | currentText is empty, length equals 0 | Pass |
| SM26 | Allow new additions after clearing | Create manager, add 'A','B', clear, add 'C','D' | manager: 'AB', clearAll(), add 'C','D' | currentText equals 'CD' | Pass |
| SM27 | Work multiple times | Create manager, add/clear/add/clear/add/clear | manager: empty, add 'X', clear, add 'Y', clear, add 'Z', clear | isEmpty remains true after each clear | Pass |
| SM28 | Clear text with special characters | Create manager, add '!','@','#', clear | manager: '!@#', clearAll() | currentText is empty | Pass |
| SM29 | Reset state completely for spelling app | Create manager, spell 'HELLO', clear, spell 'WOW' | manager: add 'HELLO', clearAll(), add 'WOW' | After clear: empty/0/true, After 'WOW': 'WOW'/3/false | Pass |
| SM30 | Report isEmpty as true when empty | Create manager, check isEmpty | manager: empty | isEmpty equals true | Pass |
| SM31 | Report isEmpty as false when has content | Create manager, add 'A', check isEmpty | manager: 'A', check isEmpty | isEmpty equals false | Pass |
| SM32 | Report correct length | Create manager, add 'A','B','C' | manager: 'ABC' | length equals 3 | Pass |
| SM33 | Update length after operations | Create manager, add/delete/clear tracking length | manager: empty, add 'X', add 'Y', delete, clear | length: 0→1→2→1→0 | Pass |
| SM34 | addLetters adds multiple letters at once | Create manager, call addLetters('HELLO') | manager: empty, text: 'HELLO' | currentText equals 'HELLO', length equals 5 | Pass |
| SM35 | addLetters throw error for empty string | Create manager, call addLetters('') | manager: empty, text: '' | Throws ArgumentError | Pass |
| SM36 | replaceText replaces entire text | Create manager, add 'A','B', replaceText('XYZ') | manager: 'AB', replaceText('XYZ') | currentText equals 'XYZ' | Pass |
| SM37 | getCharAt returns character at index | Create manager, add 'HELLO', getCharAt(0,2,4) | manager: 'HELLO', indices: 0,2,4 | results: 'H','L','O' | Pass |
| SM38 | getCharAt throw for out of bounds index | Create manager, add 'HI', getCharAt(5) | manager: 'HI', index: 5 (out of bounds) | Throws RangeError | Pass |
| SM39 | removeCharAt removes character at specific index | Create manager, add 'HELLO', removeCharAt(2) | manager: 'HELLO', removeAt: 2 | currentText equals 'HELO' | Pass |
| SM40 | toString provides readable representation | Create manager, add 'TEST', call toString | manager: 'TEST' | String contains 'TEST' and '4' (length) | Pass |
| SM41 | reset clears all text | Create manager, add 'SOMETHING', reset | manager: 'SOMETHING', reset() | isEmpty equals true, currentText is empty | Pass |
| SM42 | Handle complete spelling workflow | Create manager, spell 'FLUTTER' with error correction | manager: empty, spell with mistake, correct, continue | currentText equals 'FLUTTER' at end | Pass |
| SM43 | Handle user corrections during spelling | Create manager, add 'CAT', delete 2, add 'AR' | manager: empty, add 'CAT', deleteLastLetter() ×2, add 'AR' | currentText equals 'CAR' | Pass |
| SM44 | Handle switching between words | Create manager, add 'FIRST', clear, add 'SECOND' | manager: empty, add 'FIRST', clearAll(), add 'SECOND' | After FIRST: 'FIRST', After clear & SECOND: 'SECOND' | Pass |

## Confidence Checker Tests (CC)

| Unit Test Case ID | Test Case Description | Test Procedure | Test Data | Expected Result | Status |
|---|---|---|---|---|---|
| CC01 | Return true when confidence equals threshold | Call isConfidenceValid(0.70, threshold: 0.70) | confidence: 0.70, threshold: 0.70 | result equals true | Pass |
| CC02 | Return true when confidence exceeds threshold | Call isConfidenceValid(0.85, threshold: 0.70) | confidence: 0.85, threshold: 0.70 | result equals true | Pass |
| CC03 | Return false when confidence below threshold | Call isConfidenceValid(0.40, threshold: 0.70) | confidence: 0.40, threshold: 0.70 | result equals false | Pass |
| CC04 | Use default threshold of 0.70 when not specified | Call isConfidenceValid(0.75) and isConfidenceValid(0.65) | confidence1: 0.75, confidence2: 0.65 | resultValid equals true, resultInvalid equals false | Pass |
| CC05 | Handle perfect confidence of 1.0 | Call isConfidenceValid(1.0, threshold: 0.70) | confidence: 1.0, threshold: 0.70 | result equals true | Pass |
| CC06 | Handle zero confidence | Call isConfidenceValid(0.0, threshold: 0.70) | confidence: 0.0, threshold: 0.70 | result equals false | Pass |
| CC07 | Handle confidence very close to threshold | Call isConfidenceValid with 0.70001 and 0.69999, threshold: 0.70 | confidence1: 0.70001, confidence2: 0.69999, threshold: 0.70 | resultAbove equals true, resultBelow equals false | Pass |
| CC08 | Handle custom threshold of 0.50 | Call isConfidenceValid(0.51, 0.49) with threshold: 0.50 | confidence1: 0.51, confidence2: 0.49, threshold: 0.50 | result1 equals true, result2 equals false | Pass |
| CC09 | Handle high threshold of 0.95 | Call isConfidenceValid(0.96, 0.94) with threshold: 0.95 | confidence1: 0.96, confidence2: 0.94, threshold: 0.95 | result1 equals true, result2 equals false | Pass |
| CC10 | Handle low threshold of 0.10 | Call isConfidenceValid(0.15, threshold: 0.10) | confidence: 0.15, threshold: 0.10 | result equals true | Pass |
| CC11 | Throw error for confidence > 1.0 | Call isConfidenceValid(1.5, threshold: 0.70) | confidence: 1.5, threshold: 0.70 | Throws ArgumentError | Pass |
| CC12 | Throw error for confidence < 0.0 | Call isConfidenceValid(-0.5, threshold: 0.70) | confidence: -0.5, threshold: 0.70 | Throws ArgumentError | Pass |
| CC13 | Throw error for threshold > 1.0 | Call isConfidenceValid(0.85, threshold: 1.5) | confidence: 0.85, threshold: 1.5 | Throws ArgumentError | Pass |
| CC14 | Throw error for threshold < 0.0 | Call isConfidenceValid(0.85, threshold: -0.1) | confidence: 0.85, threshold: -0.1 | Throws ArgumentError | Pass |
| CC15 | Handle edge case: confidence 0.0, threshold 0.0 | Call isConfidenceValid(0.0, threshold: 0.0) | confidence: 0.0, threshold: 0.0 | result equals true (0.0 >= 0.0) | Pass |
| CC16 | Handle edge case: confidence 1.0, threshold 1.0 | Call isConfidenceValid(1.0, threshold: 1.0) | confidence: 1.0, threshold: 1.0 | result equals true (1.0 >= 1.0) | Pass |
| CC17 | Validate typical TFLite model outputs | Call isConfidenceValid with multiple typical values | Test cases: (0.95,0.70,true), (0.78,0.70,true), (0.70,0.70,true), (0.65,0.70,false), (0.45,0.70,false), (0.99,0.90,true) | All results match expected values | Pass |
| CC18 | Create prediction with label and confidence | Create PredictionConfidence('A', 0.85) | label: 'A', confidence: 0.85 | prediction.label equals 'A', prediction.confidence equals 0.85 | Pass |
| CC19 | Throw error for invalid confidence > 1.0 | Create PredictionConfidence('A', 1.5) | label: 'A', confidence: 1.5 | Throws ArgumentError | Pass |
| CC20 | Throw error for invalid confidence < 0.0 | Create PredictionConfidence('A', -0.1) | label: 'A', confidence: -0.1 | Throws ArgumentError | Pass |
| CC21 | Allow confidence 0.0 | Create PredictionConfidence('A', 0.0) | label: 'A', confidence: 0.0 | prediction.confidence equals 0.0 | Pass |
| CC22 | Allow confidence 1.0 | Create PredictionConfidence('A', 1.0) | label: 'A', confidence: 1.0 | prediction.confidence equals 1.0 | Pass |
| CC23 | meetsThreshold uses default threshold | Create predictions with 0.75 and 0.65, call meetsThreshold() | pred1: 0.75, pred2: 0.65 | pred1.meetsThreshold() equals true, pred2.meetsThreshold() equals false | Pass |
| CC24 | meetsThreshold accepts custom threshold | Create prediction with 0.72, call meetsThreshold(0.70, 0.75) | prediction: 0.72, threshold1: 0.70, threshold2: 0.75 | meetsThreshold(0.70) equals true, meetsThreshold(0.75) equals false | Pass |
| CC25 | Generate string representation | Create PredictionConfidence('A', 0.85), call toString | label: 'A', confidence: 0.85 | String contains 'A' and '0.85' | Pass |
| CC26 | Work with all 26 letters | Create predictions for A-Z with 0.85 confidence | labels: A-Z, confidence: 0.85 | All predictions created successfully with correct labels | Pass |
| CC27 | Filter predictions above default threshold | Create 4 predictions with confidence 0.85,0.40,0.92,0.65, filter | predictions: A(0.85), B(0.40), C(0.92), D(0.65) | filtered.length equals 2, labels: A, C | Pass |
| CC28 | Filter predictions with custom threshold | Create 3 predictions with 0.85,0.75,0.65, filter with 0.80 | predictions: A(0.85), B(0.75), C(0.65), threshold: 0.80 | filtered.length equals 1, label: A | Pass |
| CC29 | Return empty list if no predictions meet threshold | Create 3 predictions with 0.50,0.45,0.40, filter with 0.70 | predictions: A(0.50), B(0.45), C(0.40), threshold: 0.70 | filtered is empty list | Pass |
| CC30 | Return all predictions if all meet threshold | Create 3 predictions with 0.95,0.90,0.85, filter with 0.70 | predictions: A(0.95), B(0.90), C(0.85), threshold: 0.70 | filtered.length equals 3 | Pass |
| CC31 | Preserve order of predictions | Create 3 predictions Z(0.85),A(0.75),M(0.80), filter | predictions: Z(0.85), A(0.75), M(0.80) | filtered order: Z, A, M | Pass |
| CC32 | Handle empty predictions list | Call filterConfidentPredictions([]) | Empty predictions list | filtered is empty list | Pass |
| CC33 | Work with 0.0 threshold | Create predictions with 0.01,0.0, filter with 0.0 | predictions: A(0.01), B(0.0), threshold: 0.0 | filtered.length equals 2 | Pass |
| CC34 | Work with 1.0 threshold | Create predictions with 1.0,0.99, filter with 1.0 | predictions: A(1.0), B(0.99), threshold: 1.0 | filtered.length equals 1, label: A | Pass |
| CC35 | Return prediction with highest confidence | Create 3 predictions A(0.75),B(0.92),C(0.80), get highest | predictions: A(0.75), B(0.92), C(0.80) | highest.label equals 'B', highest.confidence equals 0.92 | Pass |
| CC36 | Return null for empty predictions list | Call getHighestConfidencePrediction([]) | Empty list | result equals null | Pass |
| CC37 | Return single prediction if only one exists | Create 1 prediction A(0.85), get highest | predictions: A(0.85) | highest.label equals 'A', highest.confidence equals 0.85 | Pass |
| CC38 | Handle tied confidences | Create 2 predictions with same confidence A(0.85),B(0.85), get highest | predictions: A(0.85), B(0.85) | highest.confidence equals 0.85 | Pass |
| CC39 | Work with very close confidence values | Create 3 predictions A(0.850000),B(0.850001),C(0.849999), get highest | predictions: A(0.850000), B(0.850001), C(0.849999) | highest.label equals 'B' | Pass |
| CC40 | Calculate average confidence correctly | Create 3 predictions A(0.80),B(0.90),C(1.00), calculate average | predictions: A(0.80), B(0.90), C(1.00) | average closeTo 0.90 (avg = 0.90) | Pass |
| CC41 | Return 0.0 for empty list | Call calculateAverageConfidence([]) | Empty list | average equals 0.0 | Pass |
| CC42 | Work with single prediction | Create 1 prediction A(0.75), calculate average | predictions: A(0.75) | average equals 0.75 | Pass |
| CC43 | Work with all same confidences | Create 3 predictions A(0.70),B(0.70),C(0.70), calculate average | predictions: A(0.70), B(0.70), C(0.70) | average closeTo 0.70 | Pass |
| CC44 | Handle decimal precision | Create 3 predictions A(0.333333),B(0.333333),C(0.333334), calculate average | predictions: A(0.333333), B(0.333333), C(0.333334) | average closeTo 0.333333 | Pass |
| CC45 | Return low for confidence < 0.5 | Call getConfidenceLevel with 0.0, 0.25, 0.49 | confidence values: 0.0, 0.25, 0.49 | All return ConfidenceLevel.low | Pass |
| CC46 | Return medium for 0.5 <= confidence <= 0.8 | Call getConfidenceLevel with 0.50, 0.65, 0.80 | confidence values: 0.50, 0.65, 0.80 | All return ConfidenceLevel.medium | Pass |
| CC47 | Return high for confidence > 0.8 | Call getConfidenceLevel with 0.81, 0.90, 1.0 | confidence values: 0.81, 0.90, 1.0 | All return ConfidenceLevel.high | Pass |

---

## Test Summary

- **Total Test Cases**: 123
- **Data Normalizer Tests**: 26
- **Spelling Manager Tests**: 44
- **Confidence Checker Tests**: 47
- **All Status**: Pass

### Test Coverage by Category

**Data Normalizer (DN)**: Covers coordinate normalization, landmark creation, flattening, and batch operations
- Normalization edge cases (midpoint, boundaries, clamping)
- Landmark point creation and comparison
- Flattening with validation and error handling
- Integration with screen coordinates

**Spelling Manager (SM)**: Covers text management for spelling mode
- Letter addition (single, multiple, special characters)
- Letter deletion and backspace functionality
- Text clearing and reset
- Integration workflows (spelling words, corrections, word switching)

**Confidence Checker (CC)**: Covers prediction confidence validation
- Confidence validation against thresholds
- Prediction confidence class functionality
- Filtering predictions by confidence
- Confidence statistics (highest, average)
- Confidence level categorization
