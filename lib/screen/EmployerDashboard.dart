import 'package:flutter/material.dart';
import 'package:statefulclickcounter/screen/log_in.dart';
import 'package:statefulclickcounter/screen/job_post_screen.dart';
import 'package:statefulclickcounter/screen/MyPostedJobsScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:statefulclickcounter/screen/applicantListScreen.dart';

class EmployerHomePage extends StatelessWidget {
  const EmployerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_DashboardItem> items = [
      _DashboardItem(
        title: 'Post a Job',
        icon: Icons.add_box_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JobPostScreen()),
          );
        },
      ),
      _DashboardItem(
        title: 'Manage Applicants',
        icon: Icons.people_alt_outlined,
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ApplicantListScreen()),
          );
        },
      ),
      _DashboardItem(
          title: 'My Posted Jobs',
          icon: Icons.work_outline,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MyPostedJobsScreen()),
            );
          }),
      _DashboardItem(
          title: 'Logout',
          icon: Icons.logout_rounded,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          }),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Employer Dashboard',
          style: TextStyle(
            color: Color(0xFF4B5EFC),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4B5EFC)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return _DashboardCard(item: items[index]);
          },
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Color(0xFF4B5EFC).withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(12, 0, 0, 0),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 35, color: Color(0xFF4B5EFC)),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
