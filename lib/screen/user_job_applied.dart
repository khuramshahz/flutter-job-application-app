import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:statefulclickcounter/screen/home_screen.dart';
import 'package:statefulclickcounter/screen/application_status_screen.dart';

class JobAppliedScreen extends StatefulWidget {
  @override
  _JobAppliedScreenState createState() => _JobAppliedScreenState();
}

class _JobAppliedScreenState extends State<JobAppliedScreen> {
  List<Map<String, String>> appliedJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppliedJobs();
  }

  Future<void> fetchAppliedJobs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userId = currentUser.uid;
    final jobAppliedRef = FirebaseDatabase.instance.ref('jobApplied');
    final jobsRef = FirebaseDatabase.instance.ref('jobs');

    try {
      final snapshot =
          await jobAppliedRef.orderByChild('userId').equalTo(userId).once();

      if (!snapshot.snapshot.exists || snapshot.snapshot.value == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final appliedMap = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>);

      List<Map<String, String>> jobList = [];

      for (var entry in appliedMap.entries) {
        final data = Map<String, dynamic>.from(entry.value);
        final String jobId = data['jobid']?.toString() ?? '';
        final String status = data['status']?.toString() ?? 'pending';
        final String appliedAtTimestamp = data['appliedAt']?.toString() ?? '';

        String jobTitle = 'Unknown Job';
        String jobAvailability = 'N/A';

        if (jobId.isNotEmpty) {
          final jobSnapshot = await jobsRef.child(jobId).get();
          if (jobSnapshot.exists && jobSnapshot.value != null) {
            final jobData = Map<String, dynamic>.from(jobSnapshot.value as Map);
            jobTitle = jobData['title']?.toString() ?? 'Unknown Job';
            jobAvailability = jobData['jobType']?.toString() ?? 'N/A';
          }
        }

        String formattedAppliedAt = 'N/A';
        if (appliedAtTimestamp.isNotEmpty) {
          try {
            final int timestamp = int.parse(appliedAtTimestamp);
            final DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(timestamp);
            formattedAppliedAt =
                DateFormat('MMM d, yyyy HH:mm').format(dateTime);
          } catch (e) {
            print("Error parsing timestamp: $e");
          }
        }

        jobList.add({
          'jobId': jobId,
          'jobTitle': jobTitle,
          'jobAvailability': jobAvailability,
          'status': status,
          'appliedAt': formattedAppliedAt,
        });
      }

      setState(() {
        appliedJobs = jobList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching applied jobs: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading applied jobs: $e")),
      );
    }
  }

  Widget buildJobCard(Map<String, String> job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4B5EFC),
          radius: 24,
          child: const Icon(Icons.business, color: Colors.white),
        ),
        title: Text(
          job['jobTitle'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("Type: ${job['jobAvailability'] ?? 'N/A'}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text("Applied On: ${job['appliedAt'] ?? 'N/A'}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(
              "Status: ${job['status'] != null ? job['status']![0].toUpperCase() + job['status']!.substring(1) : 'N/A'}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: job['status'] == 'shortlisted'
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ],
        ),
        trailing: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicationStatusScreen(
                  jobTitle: job['jobTitle'] ?? 'N/A',
                  status: job['status'] ?? 'pending',
                ),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF4B5EFC),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Applied Jobs",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4B5EFC),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B5EFC)))
          : appliedJobs.isEmpty
              ? const Center(
                  child: Text(
                    "You haven't applied for any jobs yet.",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  itemCount: appliedJobs.length,
                  itemBuilder: (context, index) =>
                      buildJobCard(appliedJobs[index]),
                ),
    );
  }
}
