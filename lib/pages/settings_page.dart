import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sign_language_recognition_app/services/tts_service.dart';
import 'package:sign_language_recognition_app/shared/widgets/reset_data_dialog.dart';
import 'package:sign_language_recognition_app/shared/widgets/custom_slider.dart';
import 'package:sign_language_recognition_app/shared/widgets/dashboard_block.dart';
import 'package:sign_language_recognition_app/shared/widgets/settings_switch_row.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // local state variables
  bool isTtsEnabled = true;
  bool isDarkMode = false;
  bool isShowLandmarks = true;
  bool isHaptic = true;
  bool isAutoplay = true;
  String selectedVoice = "Female Voice";
  final List<String> voices = ["Female Voice", "Male Voice"];
  final ValueNotifier<String?> _selectedVoiceListenable = ValueNotifier<String?>("Female Voice");
  double speechSpeed = 1.0;
  bool isLoading = true;
  int _speedChangeSequence = 0;

  @override
  void initState(){
    super.initState();
    _loadStoredSettings();
  }

  // load data from disk
  Future<void> _loadStoredSettings() async {
    final settings = await SettingsService.getAllSettings();
    final String storedVoice = settings['selectedVoice'] as String;
    setState(() {
      isTtsEnabled = settings['isTtsEnabled'];
      selectedVoice = voices.contains(storedVoice) ? storedVoice : voices.first;
      speechSpeed = settings['speechSpeed'];
      isDarkMode = settings['isDarkMode'];
      isShowLandmarks = settings['isShowLandmarks'];
      isHaptic = settings['isHaptic'];
      isAutoplay = settings['isAutoplay'];
      isLoading = false;
    });
    _selectedVoiceListenable.value = selectedVoice;
  }

  void _toggleTts(bool value) {
    setState(() => isTtsEnabled = value);
    SettingsService.setTts(value);
  }

  void _toggleDarkMode(bool value) {
    setState(() => isDarkMode = value);
    SettingsService.setDarkMode(value);
  }

  void _toggleShowLandmarks(bool value) {
    setState(() => isShowLandmarks = value);
    SettingsService.setShowLandmarks(value);
  }

  void _toggleHaptic(bool value) {
    setState(() => isHaptic = value);
    SettingsService.setHaptic(value);
  }

  void _toggleAutoplay(bool value) {
    setState(() => isAutoplay = value);
    SettingsService.setAutoplay(value);
  }

  Future<void> _changeVoice(String value) async {
    setState(() => selectedVoice = value);
    _selectedVoiceListenable.value = value;
    await SettingsService.setVoice(value);

    await TtsService.updateSettings(speed: speechSpeed, genderPreference: value);

    await TtsService.speakText("This is the $value");
  }

  @override
  void dispose() {
    _selectedVoiceListenable.dispose();
    super.dispose();
  }

  void _onSpeedChanged(double value) {
    setState(() => speechSpeed = value);
  }

  String _getSpeedLabel(double value) {
    if (value < 0.35) return "Slow";
    if (value > 0.65) return "Fast";
    return "Normal";
  }

  Future<void> _onSpeedChangeEnd(double value) async {
    final int sequence = ++_speedChangeSequence;

    await SettingsService.setSpeed(value);
    await TtsService.updateSettings(speed: value, genderPreference: selectedVoice);

    if (!mounted || sequence != _speedChangeSequence) {
      return;
    }

    await TtsService.stopSpeaking();

    if (!mounted || sequence != _speedChangeSequence) {
      return;
    }

    await TtsService.speakText("I will now speak at this pace.");
  }

  Future<void> _resetLearningData() async {
    try {
      final dbHelper = DBHelper();
      await dbHelper.resetLearningProgress();
      await ProfileService.resetProgressOnly();
      await StudyTrackerService.clearSessions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning progress has been reset.'),
        ),
      );

      // Prefer popping settings so pending push() callers can complete and clear UI state.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset data: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(),),);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Settings"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              SizedBox(height: 20,),
              // heading message
              Column(
                children: [
                  DashboardBlock(
                    title: "Text-to-Speech",
                    icon: Icons.volume_up_outlined,
                    iconColor: Colors.cyan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Switch
                        SettingsSwitchRow(
                          title: "Enable Text-to-Speech", 
                          description: "Hear recognized signs spoken aloud", 
                          value: isTtsEnabled, 
                          onChanged: _toggleTts,
                        ),
                        const SizedBox(height: 20),
        
                        // Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Voice Selection",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                isExpanded: true,
                                items: voices.map((String voice) {
                                  bool isSelected = voice == selectedVoice;
                                  return DropdownItem<String>(
                                    value: voice,
                                    height: 48,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            voice,
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                valueListenable: _selectedVoiceListenable,
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    await _changeVoice(newValue);
                                  }
                                },
                                // 1. STYLE THE BUTTON (The closed state)
                                buttonStyleData: ButtonStyleData(
                                  padding: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    border: Border.all(color: const Color(0xFFDEE2E6)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                // 2. STYLE THE DROPDOWN MENU (The open state)
                                dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  offset: const Offset(0, -4), // Adjusts position so it doesn't overlap
                                  elevation: 4,
                                ),
                                // 3. REMOVE INTERNAL PADDING (Allows Teal to touch the edges)
                                menuItemStyleData: const MenuItemStyleData(
                                  padding: EdgeInsets.zero, 
                                ),
                                iconStyleData: const IconStyleData(
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
        
                        const SizedBox(height: 20),
        
                        CustomeSlider(
                          value: speechSpeed,
                          onChanged: _onSpeedChanged,
                          onChangeEnd: (value) async => await _onSpeedChangeEnd(value),
                          getCurrentLabel: _getSpeedLabel,
                          title: "Speech Speed"
                        )
                      ],
        
                    ),
                  ),
        
                  SizedBox(height: 20),
        
                  // Appearance
                  DashboardBlock(
                    title: "Appearance", 
                    icon: Icons.mode_night_outlined,
                    iconColor: Colors.deepPurpleAccent,
                    flipIconHorizontally: true,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        SettingsSwitchRow(
                          title: "Dark Mode", 
                          description: "Switch to dark theme", 
                          value: isDarkMode, 
                          onChanged: _toggleDarkMode
                        ),
                      ],
                    )
                  ),

                  SizedBox(height: 20),
        
                  // Recognition Settings
                  DashboardBlock(
                    title: "Recognition Settings", 
                    icon: Icons.remove_red_eye_outlined,
                    iconColor: Colors.indigo,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        SettingsSwitchRow(
                          title: "Show Hand Landmarks", 
                          description: "Display hand tracking points on camera", 
                          value: isShowLandmarks, 
                          onChanged: _toggleShowLandmarks
                        ),
                      ],
                    )
                  ),

                  SizedBox(height: 20),

                  // General
                  DashboardBlock(
                    title: "General", 
                    icon: Icons.replay,
                    iconColor: Colors.blueGrey,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        SettingsSwitchRow(
                          title: "Haptic Feedback", 
                          description: "Vibrate for app interactions and sign recognition.", 
                          value: isHaptic, 
                          onChanged: _toggleHaptic
                        ),
                        SizedBox(height: 10),
                        SettingsSwitchRow(
                          title: "Auto-play Videos", 
                          description: "Automatically play sign demonstrrations", 
                          value: isAutoplay, 
                          onChanged: _toggleAutoplay
                        ),
                      ],
                    )
                  ),

                  SizedBox(height: 20),

                  DashboardBlock(
                    title: "Reset Data", 
                    titleColor: Colors.red,
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red,
                    borderColor: Colors.red,
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "This will permanently delete all your learning progress, quiz scores, and achievements.",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,   // background color
                                foregroundColor: Colors.white,  // text color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6), // 👈 rounded corners
                                ),
                              ),

                              onPressed: () {
                                if (SettingsService.cachedHaptic) {
                                  HapticFeedback.vibrate();
                                }
                                showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const ResetDataDialog();
                                  },
                                ).then((confirmed) {
                                  if (confirmed == true) {
                                    _resetLearningData();
                                  }
                                });
                              },
                              child: Text(
                                "Reset Learning Progress",
                                style: TextStyle(
                                  color: Colors.white
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ),

                  SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 10.0),
                            Text(
                              "MSL Translator",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Version 1.0.0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Made for Malaysian Sign Language learning",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                      
                            const SizedBox(height: 16),
                          ]
                        )
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}