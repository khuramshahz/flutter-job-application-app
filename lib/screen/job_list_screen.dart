import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:statefulclickcounter/models/job.dart';
import 'package:statefulclickcounter/screen/job_detail_screen.dart';

class JobWithKey {
  final String key;
  final Job job;

  JobWithKey({required this.key, required this.job});
}

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final databaseRef = FirebaseDatabase.instance.ref('jobs');

  Future<List<JobWithKey>> fetchJobs() async {
    final snapshot = await databaseRef.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.where((entry) => entry.value != null).map((entry) {
        final job = Job.fromJson(Map<String, dynamic>.from(entry.value));
        return JobWithKey(key: entry.key, job: job);
      }).toList();
    }
    return [];
  }

  Color _getJobTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'full time':
        return Colors.green;
      case 'part time':
        return Colors.orange;
      case 'contract':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatPostedAt(DateTime postedAt) {
    final difference = DateTime.now().difference(postedAt);
    if (difference.inDays > 1) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return '1 day ago';
    if (difference.inHours >= 1) return '${difference.inHours} hours ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B5EFC),
        title: const Text('Discover Jobs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<JobWithKey>>(
        future: fetchJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading jobs.'));
          }

          final jobList = snapshot.data ?? [];

          if (jobList.isEmpty) {
            return const Center(child: Text('No jobs found.'));
          }

          return ListView.builder(
            key: const PageStorageKey('jobList'),
            padding: const EdgeInsets.all(16),
            itemCount: jobList.length,
            itemBuilder: (context, index) {
              final job = jobList[index].job;
              final jobKey = jobList[index].key;

              return GestureDetector(
                onTap: () async {
                  final jobRef =
                      FirebaseDatabase.instance.ref('jobs/$jobKey/views');
                  final snapshot = await jobRef.get();
                  int currentViews = 0;
                  if (snapshot.exists && snapshot.value is int) {
                    currentViews = snapshot.value as int;
                  }
                  await jobRef.update({'views': currentViews + 1});

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(job: job, jobkey: jobKey),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFFF5F6FA),
                              child: Icon(Icons.business,
                                  color: Color(0xFF4B5EFC)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.title,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(job.company,
                                      style: TextStyle(
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                            Text(
                              _formatPostedAt(job.postedAt),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildInfoChip(
                                Icons.location_on_outlined, job.location),
                            _buildInfoChip(
                                Icons.attach_money_outlined, job.salary),
                            _buildInfoChip(Icons.work_outline, job.jobType,
                                color: _getJobTypeColor(job.jobType)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      JobDetailScreen(job: job, jobkey: jobKey),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B5EFC),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Apply',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey.shade200).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color ?? Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
