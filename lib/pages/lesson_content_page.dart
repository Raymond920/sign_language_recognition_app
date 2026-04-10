import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';

class LessonDetail {
  final Lesson info;
  final List<Sign> signs;

  LessonDetail({required this.info, required this.signs});
}

// TODO: call sqlite database to join and map results to models
// Future<List<Sign>> getSignsForLesson(int lessonId) async {
//   final db = await database;

// }

// TODO: Remove these mock data for UI design
final LessonDetail mockLessonDetail = LessonDetail(
  info: Lesson(
    id: 1,
    name: "Alphabet Group 1: A, B, C",
    description: "Learn the first 3 letters",
    signCount: 5,
    progress: 0.4,
  ),
  signs: [
    Sign(
      id: 101,
      name: "Letter A",
      targetLabel: "A",
      imagePath: "assets/images/signs/A.jpg",
      tutorialText: "Make a fist|Keep thumb at the side|Hold hand upright",
    ),
    Sign(
      id: 102,
      name: "Letter B",
      targetLabel: "B",
      imagePath: "assets/images/signs/B.jpg",
      tutorialText: "Open your palm|Tuck your thumb in|Keep fingers together",
    ),
    Sign(
      id: 103,
      name: "Letter C",
      targetLabel: "C",
      imagePath: "assets/images/signs/C.jpg",
      tutorialText: "Curve your fingers|Keep thumb away from palm|Form a 'C' shape",
    ),
    Sign(
      id: 104,
      name: "Letter D",
      targetLabel: "D",
      imagePath: "assets/images/signs/D.jpg",
      tutorialText: "this is D|Loreaum Elpsum|Testing",
    ),
    Sign(
      id: 105,
      name: "Letter E",
      targetLabel: "E",
      imagePath: "assets/images/signs/E.jpg",
      tutorialText: "this is E|Loreaum Elpsum|Testing",
    ),
  ],
);


class LessonContentPage extends StatefulWidget {
  const LessonContentPage({
    super.key, 
    required LessonMock lesson
  });

  @override
  State<LessonContentPage> createState() => _LessonContentPageState();
}

class _LessonContentPageState extends State<LessonContentPage> {
  int currentIndex = (mockLessonDetail.info.progress * mockLessonDetail.info.signCount).round();   // Step tracking
  bool hasDetectedCorrectSign = false;  // Simulating the "Great Job" overlay

  @override
  Widget build(BuildContext context) {
    final currentSign = mockLessonDetail.signs[currentIndex];
    final totalSteps = mockLessonDetail.signs.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back),
        ),
        // TODO: Replace mock data with real data from sqlite
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mockLessonDetail.info.name, style: const TextStyle(fontSize: 16),),
            Text(
              "Step ${currentIndex + 1} of $totalSteps",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              SizedBox(height: 12,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / totalSteps,
                  backgroundColor: Colors.indigo[100],
                  color: Colors.indigoAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  // Learning Card
                  _buildInstructionCard(currentSign),

                  const SizedBox(height: 20),

                  // Practice Card
                  _buildPracticeCard(currentSign),

                ],
              ),
              
              // Bottom Navigation Buttons
              _buildBottomNav(totalSteps),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(Sign sign) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Learning: ${sign.name}", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 150, width: 150,
              // color: Colors.grey[200],
              // child: const Icon(Icons.image, size: 50, color: Colors.grey),
              child: Image.asset(
                sign.imagePath
              )
            ),
          ),
          const SizedBox(height: 20),
          const Text("How to sign:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Using our split logic for bullet points
          ...sign.instructions.map((text) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text("• $text", style: const TextStyle(color: Colors.blueGrey)),
          )),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    );
  }
  
  Widget _buildPracticeCard(Sign currentSign) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Practice Time", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          // Camera Placeholder
          Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF121826), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.videocam, color: Colors.white, size: 40)),
          ),
          const SizedBox(height: 15),
          
          // Feedback Badge (Mocking a successful detection)
          if (hasDetectedCorrectSign)
            Container(
              padding: const EdgeInsets.all(12),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40,),
                  const SizedBox(height: 8),
                  Text("Great job!", style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.bold)),
                  Text("Your sign matches perfectly", style: TextStyle(fontSize: 14, color: Colors.green[800], fontWeight: FontWeight.normal)),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNav(int totalSteps) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: currentIndex > 0 ? () => setState(() => currentIndex--) : null,
            child: const Text("Previous"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (currentIndex < totalSteps - 1) {
                setState(() {
                  currentIndex++;
                  hasDetectedCorrectSign = false; // Reset for next step
                });
              } else {
                // TODO: Lesson Finished Logic
                Navigator.pop(context);
              }
            },
            child: Text(currentIndex == totalSteps - 1 ? "Complete" : "Next Step"),
          ),
        ],
      ),
    );
  }
}