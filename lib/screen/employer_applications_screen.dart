import 'package:flutter/material.dart';

class EmployerApplicationsScreen extends StatelessWidget {
  final String jobTitle;
  final List<Map<String, String>> applicants;

  const EmployerApplicationsScreen({
    super.key,
    required this.jobTitle,
    required this.applicants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants for $jobTitle',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: applicants.length,
          itemBuilder: (context, index) {
            final applicant = applicants[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF5F6FA),
                  child: Icon(Icons.person,
                      color: const Color(0xFF4B5EFC), size: 24),
                ),
                title: Text(
                  applicant['name']!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${applicant['email']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                trailing: Text(
                  'Applied for: ${applicant['jobTitle']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
