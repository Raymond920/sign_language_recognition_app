import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditMode = false;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  File? _profileImage;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: ProfileService.cachedUsername);
    _emailController = TextEditingController(text: "learner@example.com");
    _totalPoints = ProfileService.cachedTotalPoints;
    
    // Listen for username changes
    ProfileService.usernameNotifier.addListener(_onUsernameChanged);
    // Listen for points changes
    ProfileService.totalPointsNotifier.addListener(_onPointsChanged);
    _loadProfileImage();
  }

  void _onUsernameChanged() {
    setState(() {
      _usernameController.text = ProfileService.cachedUsername;
    });
  }

  void _onPointsChanged() {
    setState(() {
      _totalPoints = ProfileService.cachedTotalPoints;
    });
  }

  @override
  void dispose() {
    ProfileService.usernameNotifier.removeListener(_onUsernameChanged);
    ProfileService.totalPointsNotifier.removeListener(_onPointsChanged);
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final cachedImage = ProfileService.cachedProfileImage;
    
    if (cachedImage != null && await cachedImage.exists()) {
      setState(() {
        _profileImage = cachedImage;
      });
    }
  }

  Future<void> _saveProfileImage(File imageFile) async {
    try {
      print('\n📷 [PROFILE] _saveProfileImage() called');
      print('📷 [PROFILE] Source image file: ${imageFile.path}');
      
      final directory = await getApplicationDocumentsDirectory();
      final String dirPath = directory.path;
      print('📷 [PROFILE] Documents directory: $dirPath');
      
      // Create profile_pictures subdirectory for organization
      final profileDir = Directory('$dirPath/profile_pictures');
      if (!await profileDir.exists()) {
        print('📷 [PROFILE] profile_pictures subdirectory did not exist, creating...');
        await profileDir.create(recursive: true);
      }
      print('📷 [PROFILE] profile_pictures directory: ${profileDir.path}');
      
      // Delete all old profile images to avoid storage bloat
      try {
        final files = profileDir.listSync();
        print('📷 [PROFILE] Found ${files.length} files in profile_pictures directory');
        for (var file in files) {
          if (file is File && file.path.contains('profile_')) {
            await file.delete();
            print('✓ [PROFILE] Deleted old profile image: ${file.path}');
          }
        }
      } catch (e) {
        print('❌ [PROFILE] Error cleaning old images: $e');
      }
      
      // Use timestamp to create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName = 'profile_$timestamp.png';
      final String fullPath = '${profileDir.path}/$fileName';
      
      print('📷 [PROFILE] New image path: $fullPath');
      print('📷 [PROFILE] Copying image from ${imageFile.path}...');
      
      // Copy the image file to permanent storage
      final File savedImage = await imageFile.copy(fullPath);
      
      // Verify the file was actually saved before storing the path
      if (await savedImage.exists()) {
        print('✓ [PROFILE] Image file verified to exist at: $fullPath');
        
        // Use ProfileService to cache the image path (includes validation)
        print('📷 [PROFILE] Calling ProfileService.setProfileImagePath()...');
        await ProfileService.setProfileImagePath(fullPath);
        
        // Clear image cache to force reload
        imageCache.clear();
        imageCache.clearLiveImages();
        
        setState(() {
          _profileImage = savedImage;
        });
        
        print('✓ [PROFILE] Profile picture updated successfully\n');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully")),
        );
      } else {
        throw Exception('Image file was not saved properly');
      }
    } catch (e) {
      print('❌ [PROFILE] Error saving profile picture: $e\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile picture: $e")),
      );
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: const Color(0xFF5B7FFF),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockDimensionSwapEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final File croppedFileAsFile = File(croppedFile.path);
          await _saveProfileImage(croppedFileAsFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _saveChanges() {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot be empty")),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email cannot be empty")),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    // Save username to ProfileService
    ProfileService.setUsername(_usernameController.text);
    
    setState(() {
      _isEditMode = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  void _cancelEdit() {
    _usernameController.text = ProfileService.cachedUsername;
    _emailController.text = "learner@example.com";
    setState(() {
      _isEditMode = false;
    });
  }

  Widget _buildProfilePicture() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Circular profile border with background
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFE8EBFF),
                    border: Border.all(
                      color: const Color(0xFF5B7FFF),
                      width: 4,
                    ),
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImage == null
                      ? const Icon(
                          Icons.person,
                          size: 80,
                          color: Color(0xFF5B7FFF),
                        )
                      : null,
                ),
                // Camera icon button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndCropImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B7FFF),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap camera icon to upload photo',
              style: TextStyle(
                color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF808080),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Username
            Text(
              "Username",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _isEditMode
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                      border: Border.all(
                        color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      style: TextStyle(
                        color: isDark ? colorScheme.onSurface : Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF5B7FFF), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _usernameController.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? colorScheme.onSurface : const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 16),

            // Email
            Text(
              "Email",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _isEditMode
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                      border: Border.all(
                        color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: isDark ? colorScheme.onSurface : Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF5B7FFF), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _emailController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? colorScheme.onSurface : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

            const SizedBox(height: 20),

            // Buttons
            _isEditMode
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B7FFF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFF5B7FFF), width: 1),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B7FFF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
          ],
        )
      )
    );
  }

  Widget _buildStatsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Statistics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFF5B7FFF), size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Points",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF808080),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _totalPoints.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B7FFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildProfilePicture(),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildAccountInfo(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}