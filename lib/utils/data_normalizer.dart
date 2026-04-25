/// Data Normalizer utility for preprocessing hand landmark data
/// Handles normalization of coordinates and flattening of landmark structures

/// Normalizes raw hand landmark coordinates from screen pixels to 0.0-1.0 range
/// 
/// Parameters:
/// - [value]: The raw pixel coordinate value (e.g., x or y position)
/// - [screenDimension]: The screen dimension in pixels (width for x, height for y)
/// 
/// Returns: The normalized value in range [0.0, 1.0]
/// 
/// Example:
/// ```
/// double normalizedX = normalizeLandmarkCoordinate(540, 1080); // Returns 0.5
/// double normalizedY = normalizeLandmarkCoordinate(200, 1920); // Returns ~0.104
/// ```
double normalizeLandmarkCoordinate(double value, double screenDimension) {
  if (screenDimension <= 0) {
    throw ArgumentError('Screen dimension must be positive');
  }
  
  final normalized = value / screenDimension;
  
  // Clamp value to [0.0, 1.0] to handle edge cases
  return normalized.clamp(0.0, 1.0);
}

/// Represents a 3D hand landmark point with x, y, z coordinates
class LandmarkPoint {
  final double x;
  final double y;
  final double z;

  LandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'LandmarkPoint(x: $x, y: $y, z: $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandmarkPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}

/// Flattens a list of 21 hand landmarks into a flat List<double> of length 63
/// 
/// Hand landmarks structure: Each of 21 points has (x, y, z) coordinates = 63 total values
/// The hand has 21 keypoints: wrist (1) + fingers (4*5)
/// 
/// Parameters:
/// - [landmarks]: List of exactly 21 LandmarkPoint objects
/// 
/// Returns: A flat List<double> of 63 values in order: [x1, y1, z1, x2, y2, z2, ..., x21, y21, z21]
/// 
/// Throws: [ArgumentError] if landmarks list doesn't contain exactly 21 points
/// 
/// Example:
/// ```
/// List<LandmarkPoint> landmarks = List.generate(21, (i) => LandmarkPoint(x: i*0.1, y: i*0.2, z: i*0.3));
/// List<double> flat = flattenLandmarks(landmarks);
/// assert(flat.length == 63);
/// assert(flat[0] == 0.0);  // x of first landmark
/// assert(flat[1] == 0.0);  // y of first landmark
/// assert(flat[2] == 0.0);  // z of first landmark
/// assert(flat[3] == 0.1);  // x of second landmark
/// ```
List<double> flattenLandmarks(List<LandmarkPoint> landmarks) {
  const int expectedLandmarkCount = 21;
  
  if (landmarks.length != expectedLandmarkCount) {
    throw ArgumentError(
      'Expected exactly $expectedLandmarkCount landmarks, got ${landmarks.length}',
    );
  }

  final List<double> flatList = [];

  for (final landmark in landmarks) {
    flatList.add(landmark.x);
    flatList.add(landmark.y);
    flatList.add(landmark.z);
  }

  assert(flatList.length == 63, 'Flattened list should have 63 elements');

  return flatList;
}

/// Batch flatten multiple hand detection results
/// Useful for processing data from detected hands
List<List<double>> batchFlattenLandmarks(List<List<LandmarkPoint>> batchLandmarks) {
  return batchLandmarks.map((landmarks) => flattenLandmarks(landmarks)).toList();
}
