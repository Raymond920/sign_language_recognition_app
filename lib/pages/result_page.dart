import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';

class ResultPage extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  final int correctScore;
  final int wrongScore;
  const ResultPage({
    super.key, 
    required this.quizId,
    required this.quizTitle,
    required this.correctScore, 
    required this.wrongScore
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late double _scorePercentage;
  late int _totalQuestions;
  static const int _passingScore = 60;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _totalQuestions = widget.correctScore + widget.wrongScore;
    _scorePercentage = _totalQuestions > 0 
        ? (widget.correctScore / _totalQuestions) * 100 
        : 0;
    
    // Save the score to database
    _saveScoreToDatabase();
  }

  Future<void> _saveScoreToDatabase() async {
    try {
      final scorePercentage = _scorePercentage.toInt();
      
      // Get the current best score for this quiz from QUIZ_PROGRESS table
      final db = await _dbHelper.database;
      final result = await db.query(
        'QUIZ_PROGRESS',
        columns: ['best_score', 'points_claimed'],
        where: 'quiz_id = ?',
        whereArgs: [widget.quizId],
      );
      
      int oldBestScore = 0;
      int pointsClaimed = 0;
      if (result.isNotEmpty) {
        oldBestScore = result[0]['best_score'] as int? ?? 0;
        pointsClaimed = result[0]['points_claimed'] as int? ?? 0;
      }
      
      // Compare and save only if new score is higher
      if (scorePercentage > oldBestScore) {
        await _dbHelper.updateQuizScore(widget.quizId, scorePercentage);
        
        // Notify ALL listeners that quiz was completed (only if score > 60)
        if (scorePercentage > 60) {
          ProfileService.markQuizCompleted(widget.quizId);
        }
        
        // If new score is 100% and points haven't been claimed, claim them
        if (scorePercentage == 100 && pointsClaimed == 0) {
          final claimed = await ProfileService.claimQuizPoints(widget.quizId, scorePercentage);
          if (claimed) {
            // Update points_claimed flag in database
            await db.update(
              'QUIZ_PROGRESS',
              {'points_claimed': 1},
              where: 'quiz_id = ?',
              whereArgs: [widget.quizId],
            );
          }
        }
      } else if (scorePercentage == oldBestScore && scorePercentage > 60) {
        // Still mark as "viewed" for tracking even if score didn't change (only if > 60)
        ProfileService.markQuizCompleted(widget.quizId);
      } else if (scorePercentage > 60 && scorePercentage < oldBestScore) {
        // Still mark as "viewed" for tracking even if score is lower (only if > 60)
        ProfileService.markQuizCompleted(widget.quizId);
      } else {
      }
    } catch (e) {
      print('❌ Error saving quiz score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Override back button to behave like "Try Again"
        Navigator.pop(context); // Remove ResultPage
        Navigator.pop(context); // Remove QuizContentPage, back to QuizListPage
      },
      child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6C5CE7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Column(
                children: [
                  Icon(
                    _scorePercentage >= _passingScore 
                        ? Icons.emoji_events 
                        : Icons.center_focus_strong,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _scorePercentage >= _passingScore
                        ? 'Quiz Completed!'
                        : 'Keep Practicing!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.quizTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Score Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Column(
                  children: [
                    // Score Circle
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _scorePercentage >= _passingScore
                            ? const Color(0xFFE4F5E9)  // Light green
                            : const Color(0xFFFFE4E4),  // Light red
                      ),
                      child: Center(
                        child: Text(
                          '${_scorePercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _scorePercentage >= _passingScore
                                ? const Color(0xFF2E7D32)  // Dark green
                                : const Color(0xFFFF6B6B),  // Red
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _scorePercentage / 100,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE8E8FF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _scorePercentage >= _passingScore
                                  ? const Color(0xFF6C5CE7)
                                  : const Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score $_passingScore% or higher to pass',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Correct Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.correctScore.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Correct',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Wrong Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cancel,
                            color: Color(0xFFFF6B6B),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.wrongScore.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Wrong',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Motivational Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFF9B59B6),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Job!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _scorePercentage >= _passingScore
                                ? "You're on the right track. Try reviewing the missed questions."
                                : 'Practice makes perfect! Review the lessons and try again.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Pop back to quiz list - QuizzesListPage will auto-refresh on resume
                      Navigator.pop(context); // Remove ResultPage
                      Navigator.pop(context); // Remove QuizContentPage, back to QuizListPage
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _scorePercentage >= _passingScore
                          ? 'Continue Learning'
                          : 'Try Again',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}