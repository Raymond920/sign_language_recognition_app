import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sign_language_recognition_app/services/profile_service.dart';

class ProfileAvatar extends StatefulWidget {
  final File? profileImage;
  final double radius;
  final Color backgroundColor;
  final IconData iconData;
  final Color iconColor;
  final double iconSize;

  const ProfileAvatar({
    Key? key,
    required this.profileImage,
    this.radius = 30,
    required this.backgroundColor,
    this.iconData = Icons.person,
    required this.iconColor,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageError = false;
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    print('👤 [AVATAR] initState called');
    print('👤 [AVATAR] profileImage passed: ${widget.profileImage?.path}');
    
    // Listen for profile image changes from ProfileService
    ProfileService.profileImageNotifier.addListener(_onProfileImageChanged);
    
    _validateImageFile();
  }

  @override
  void dispose() {
    // Clean up the listener
    ProfileService.profileImageNotifier.removeListener(_onProfileImageChanged);
    super.dispose();
  }

  void _onProfileImageChanged() {
    print('👤 [AVATAR] ProfileService image changed, revalidating...');
    _validateImageFile();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('👤 [AVATAR] didUpdateWidget called');
    print('👤 [AVATAR] old image: ${oldWidget.profileImage?.path}');
    print('👤 [AVATAR] new image: ${widget.profileImage?.path}');
    // Re-validate if the profile image changed
    if (oldWidget.profileImage != widget.profileImage) {
      print('👤 [AVATAR] Image changed, re-validating...');
      _validateImageFile();
    }
  }

  Future<void> _validateImageFile() async {
    print('👤 [AVATAR] _validateImageFile() called');
    if (widget.profileImage != null) {
      final exists = await widget.profileImage!.exists();
      print('👤 [AVATAR] File exists: $exists at ${widget.profileImage!.path}');
      setState(() {
        _fileExists = exists;
        _imageError = !exists;
      });
      if (!exists) {
        print('⚠️ [AVATAR] Profile image file does not exist: ${widget.profileImage!.path}');
      } else {
        print('✓ [AVATAR] Profile image file exists: ${widget.profileImage!.path}');
      }
    } else {
      print('👤 [AVATAR] profileImage is null');
      setState(() {
        _fileExists = false;
        _imageError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = widget.profileImage != null && _fileExists && !_imageError;
    print('👤 [AVATAR] build() - hasValidImage: $hasValidImage, fileExists: $_fileExists, error: $_imageError, image: ${widget.profileImage?.path}');

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: hasValidImage 
          ? FileImage(widget.profileImage!)
          : null,
      onBackgroundImageError: hasValidImage
          ? (exception, stackTrace) {
              setState(() {
                _imageError = true;
              });
              print('✗ Error loading profile image: $exception');
            }
          : null,
      child: (!hasValidImage)
          ? Icon(
              widget.iconData,
              color: widget.iconColor,
              size: widget.iconSize,
            )
          : null,
    );
  }
}
