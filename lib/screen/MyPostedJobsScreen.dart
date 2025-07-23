import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:statefulclickcounter/models/job.dart';

class JobWithKey {
  final String key;
  final Job job;

  JobWithKey({required this.key, required this.job});
}

class MyPostedJobsScreen extends StatefulWidget {
  const MyPostedJobsScreen({super.key});

  @override
  _MyPostedJobsScreenState createState() => _MyPostedJobsScreenState();
}

class _MyPostedJobsScreenState extends State<MyPostedJobsScreen> {
  List<JobWithKey> postedJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPostedJobs();
  }

  Future<void> fetchPostedJobs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userId = currentUser.uid;
    final jobsRef = FirebaseDatabase.instance.ref('jobs');

    try {
      final DataSnapshot snapshot =
          await jobsRef.orderByChild('employerId').equalTo(userId).get();

      if (!snapshot.exists || snapshot.value == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<JobWithKey> fetchedJobs = [];

      data.forEach((key, value) {
        if (value != null) {
          try {
            final job = Job.fromJson(Map<String, dynamic>.from(value));
            fetchedJobs.add(JobWithKey(key: key, job: job));
          } catch (e) {
            print("Error parsing job $key: $e");
          }
        }
      });

      fetchedJobs.sort((a, b) => b.job.postedAt.compareTo(a.job.postedAt));

      setState(() {
        postedJobs = fetchedJobs;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching posted jobs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  MaterialColor _getJobTypeColor(String type) {
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

  String _formatDateSince(DateTime postedAt) {
    final difference = DateTime.now().difference(postedAt);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildJobCard(Job job, String jobKey) {
    return Card(
      key: ValueKey(jobKey),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5EFC),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (job.jobType.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getJobTypeColor(job.jobType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job.jobType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getJobTypeColor(job.jobType)[900],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.company,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, job.location),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.attach_money, job.salary,
                color: Colors.green[700]),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.lightbulb_outline,
                (job.skills as List?)?.join(', ') ?? 'None'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Posted: ${_formatDateSince(job.postedAt)}',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                TextStyle(fontSize: 13, color: color ?? Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Posted Jobs",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4B5EFC),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B5EFC)))
          : postedJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You haven't posted any jobs yet.",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPostedJobs,
                  child: ListView.builder(
                    key: const PageStorageKey('myPostedJobsList'),
                    itemCount: postedJobs.length,
                    itemBuilder: (context, index) {
                      final jobWithKey = postedJobs[index];
                      return _buildJobCard(jobWithKey.job, jobWithKey.key);
                    },
                  ),
                ),
    );
  }
}
