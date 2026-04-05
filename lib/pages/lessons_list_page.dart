import 'package:flutter/material.dart';

class LessonsListPage extends StatefulWidget {
  const LessonsListPage({
    super.key,
  });

  @override
  State<LessonsListPage> createState() => _LessonsListPageState();
}

class _LessonsListPageState extends State<LessonsListPage> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Lessons"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget> [
                SizedBox(height: 40,),
                // heading message
                Column(
                  children: [
                    Text(
                      "Ready to Learn?",
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      "Choose your learning path to improve your MSL skills",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Color.fromRGBO(0, 0, 0, 0.4)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}