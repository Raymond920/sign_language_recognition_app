import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';

class SignDetailPage extends StatefulWidget {
  const SignDetailPage({
    super.key,
    required this.sign,
  });

  final Sign sign;

  @override
  State<SignDetailPage> createState() => _SignDetailPageState();
}

class _SignDetailPageState extends State<SignDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.sign.name),
      ),
      body: Center()
    );
  }
}