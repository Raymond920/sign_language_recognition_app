import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'user@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: const Text('+1 234 567 8900'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: const Text('New York, USA'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}