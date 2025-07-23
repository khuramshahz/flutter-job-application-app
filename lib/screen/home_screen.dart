import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_list_screen.dart';
import 'package:statefulclickcounter/screen/log_in.dart';
import 'package:statefulclickcounter/screen/user_job_applied.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Guest";
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Home', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Welcome!"),
              accountEmail: Text(userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 42, color: Color(0xFF4B5EFC)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF4B5EFC)),
            ),
            _drawerItem(Icons.assignment, "Applied Jobs", () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => JobAppliedScreen()));
            }),
            _drawerItem(Icons.settings, "Settings", () {
              Navigator.pop(context);
            }),
            _drawerItem(Icons.logout, "Logout", () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            }),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerSection(context),
            const SizedBox(height: 30),
            _sectionTitle("Explore Categories"),
            _categorySection(),
            const SizedBox(height: 30),
            _sectionTitle("Latest Jobs"),
            _buildJobCard(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4B5EFC)),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Widget _headerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Discover 1000+ Jobs",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5EFC)),
        ),
        const SizedBox(height: 8),
        Text(
          "Start your career journey today",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search for jobs...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
  }

  Widget _categorySection() {
    final categories = [
      {"icon": Icons.school, "title": "Education"},
      {"icon": Icons.computer, "title": "IT"},
      {"icon": Icons.local_hospital, "title": "Health"},
      {"icon": Icons.build, "title": "Mechanical"},
      {"icon": Icons.train, "title": "Transport"},
    ];

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFF5F6FA),
                  child: Icon(item['icon'] as IconData,
                      size: 30, color: Color(0xFF4B5EFC)),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFF4B5EFC),
              child: Icon(Icons.business, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Junior Flutter Developer",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Softtech Solutions • Remote",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text("\$1200/month",
                      style: TextStyle(color: Colors.green[700], fontSize: 14)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4B5EFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobListScreen()),
                );
              },
              child: Text("Apply", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
