import 'package:flutter/material.dart';
import '../models/job.dart';
import 'job_apply.dart';
import 'package:intl/intl.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;
  final String jobkey;

  const JobDetailScreen({required this.job, required this.jobkey, Key? key})
      : super(key: key);

  void applyForJob(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyForJobScreen(job: job, jobkey: jobkey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4B5EFC),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildSectionCard('Job Description', job.description),
              const SizedBox(height: 16),
              _buildSectionCard('Requirements', job.requirements),
              const SizedBox(height: 16),
              _buildAdditionalInfoCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildApplyButton(context),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF5F6FA),
              child: Icon(Icons.business_center,
                  size: 30, color: const Color(0xFF4B5EFC)),
            ),
            const SizedBox(height: 16),
            Text(
              job.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.company,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money,
                    color: Colors.green.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  job.salary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String content) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5EFC),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    final formattedDate = DateFormat.yMMMMd().format(job.postedAt);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5EFC),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile('Job Type', job.jobType, Icons.work_outline),
            const Divider(),
            _buildInfoTile('Skills Required', job.skills.join(', '),
                Icons.star_border_purple500_outlined),
            const Divider(),
            _buildInfoTile(
                'Posted On', formattedDate, Icons.calendar_today_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF4B5EFC).withOpacity(0.6)),
      title: Text(
        title,
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ElevatedButton(
        onPressed: () => applyForJob(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4B5EFC),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Apply Now',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
