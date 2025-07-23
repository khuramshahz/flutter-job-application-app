import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class JobApplicantsDetailScreen extends StatefulWidget {
  final String jobKey;
  final String jobTitle;

  const JobApplicantsDetailScreen({
    super.key,
    required this.jobKey,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsDetailScreen> createState() =>
      _JobApplicantsDetailScreenState();
}

class _JobApplicantsDetailScreenState extends State<JobApplicantsDetailScreen> {
  late Future<List<Map<String, dynamic>>> _applicantsFuture;

  final databaseRef = FirebaseDatabase.instance.ref();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<List<double>> _getTextEmbedding(String text) async {
    final url = Uri.parse('http://192.168.2.103:5000/embed');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'text': text}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['vector'] is List) {
          return List<double>.from(
              data['vector'].map((x) => (x as num).toDouble()));
        } else {
          throw Exception(
              'Invalid response format: "vector" field missing or malformed');
        }
      } else {
        print(
            'Server responded with status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to get embedding. Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching embedding: $e');
      if (e is http.ClientException) {
        throw Exception(
            'Network error: Could not connect to embedding service. Is the server running at $url?');
      } else if (e is FormatException) {
        throw Exception('Response format error from embedding service.');
      } else if (e is TimeoutException) {
        throw Exception(
            'Embedding service timed out. Is the server running and responsive?');
      }
      throw Exception('An unknown error occurred with embedding service: $e');
    }
  }

  double _calculateCosineSimilarity(
      List<double> vectorA, List<double> vectorB) {
    if (vectorA.isEmpty ||
        vectorB.isEmpty ||
        vectorA.length != vectorB.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      magnitudeA += vectorA[i] * vectorA[i];
      magnitudeB += vectorB[i] * vectorB[i];
    }

    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    if (magnitudeA == 0 || magnitudeB == 0) {
      return 0.0;
    }

    return dotProduct / (magnitudeA * magnitudeB);
  }

  @override
  void initState() {
    super.initState();
    _applicantsFuture = _fetchApplicantsForJob();
  }

  DateTime _parseTimestampToDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _fetchApplicantsForJob() async {
    if (currentUser == null) {
      return [];
    }

    final jobAppliedRef = databaseRef.child('jobApplied');
    final usersRef = databaseRef.child('users');
    final jobsRef = databaseRef.child('jobs');

    List<Map<String, dynamic>> applicantsList = [];

    try {
      final jobSnapshot = await jobsRef.child(widget.jobKey).get();
      String jobContext = '';
      List<double> jobEmbedding = [];

      if (jobSnapshot.exists && jobSnapshot.value != null) {
        final Map<String, dynamic> jobDetailsMap =
            Map<String, dynamic>.from(jobSnapshot.value as Map);
        final String jobDescription =
            jobDetailsMap['description']?.toString() ?? '';
        final String jobRequirements =
            jobDetailsMap['requirements']?.toString() ?? '';
        jobContext = '$jobDescription $jobRequirements'.trim();

        if (jobContext.isNotEmpty) {
          jobEmbedding = await _getTextEmbedding(jobContext);
          print('Job Embedding fetched successfully.');
        } else {
          print('Job context is empty, cannot generate embedding.');
        }
      } else {
        print(
            'Job details not found for key: ${widget.jobKey}. Similarity will be 0.');
      }

      final applicationsSnapshot = await jobAppliedRef
          .orderByChild('jobid')
          .equalTo(widget.jobKey)
          .get();

      if (!applicationsSnapshot.exists || applicationsSnapshot.value == null) {
        return [];
      }

      final Map<String, dynamic> jobApplicationsData =
          Map<String, dynamic>.from(applicationsSnapshot.value as Map);

      for (var appEntry in jobApplicationsData.entries) {
        final String appId = appEntry.key;
        final Map<String, dynamic> applicationMap =
            Map<String, dynamic>.from(appEntry.value);

        final String applicantUserId =
            applicationMap['userId']?.toString() ?? '';

        if (applicantUserId.isNotEmpty) {
          final userSnapshot = await usersRef.child(applicantUserId).get();

          if (userSnapshot.exists && userSnapshot.value != null) {
            final Map<String, dynamic> applicantDetails =
                Map<String, dynamic>.from(userSnapshot.value as Map);

            final String coverLetter =
                applicationMap['coverLetter']?.toString() ??
                    'No cover letter provided.';

            double similarityScore = 0.0;
            if (jobEmbedding.isNotEmpty && coverLetter.isNotEmpty) {
              final List<double> coverLetterEmbedding =
                  await _getTextEmbedding(coverLetter);
              similarityScore = _calculateCosineSimilarity(
                  jobEmbedding, coverLetterEmbedding);
            }

            applicantsList.add({
              'application': {
                'id': appId,
                'coverLetter': coverLetter,
                'similarityScore': similarityScore,
                ...applicationMap
              },
              'applicantDetails': applicantDetails,
            });
          } else {
            applicantsList.add({
              'application': {
                'id': appId,
                'coverLetter': 'No cover letter provided.',
                'similarityScore': 0.0,
                ...applicationMap
              },
              'applicantDetails': {
                'name': 'Unknown User (ID: $applicantUserId)',
                'email': 'N/A'
              },
            });
          }
        }
      }

      applicantsList.sort((a, b) {
        final double scoreA =
            (a['application']['similarityScore'] as num?)?.toDouble() ?? 0.0;
        final double scoreB =
            (b['application']['similarityScore'] as num?)?.toDouble() ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

      return applicantsList.take(5).toList();
    } catch (e) {
      print("Error in _fetchApplicantsForJob: $e");
      rethrow;
    }
  }

  Future<void> _toggleShortlistStatus(
      String applicationId, bool currentStatus) async {
    final newStatus = currentStatus ? 'pending' : 'shortlisted';
    try {
      await databaseRef.child('jobApplied').child(applicationId).update({
        'status': newStatus,
      });
      setState(() {
        _applicantsFuture = _fetchApplicantsForJob();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applicant ${newStatus == 'shortlisted' ? 'shortlisted' : 'status reverted to pending'}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error toggling shortlist status for applicant: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update applicant status. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateSince(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Applicants for: ${widget.jobTitle}",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4B5EFC)),
                  SizedBox(height: 10),
                  Text(
                    "Fetching applicants and calculating similarity...",
                    style: TextStyle(color: Color(0xFF4B5EFC), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            print("FutureBuilder Error (Detail Screen): ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(
                    'Error loading applicants: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _applicantsFuture = _fetchApplicantsForJob();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> applicants = snapshot.data ?? [];

          if (applicants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No applicants found for this job or after filtering for top 5.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _applicantsFuture = _fetchApplicantsForJob();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final applicantData = applicants[index];
                final Map<String, dynamic> application =
                    Map<String, dynamic>.from(
                        applicantData['application'] ?? {});
                final Map<String, dynamic> applicantDetails =
                    Map<String, dynamic>.from(
                        applicantData['applicantDetails'] ?? {});

                final String applicationId =
                    application['id']?.toString() ?? '';
                final String applicantName =
                    applicantDetails['name']?.toString() ?? 'Unknown Applicant';
                final String applicantEmail =
                    applicantDetails['email']?.toString() ?? 'N/A';
                final DateTime appliedAt =
                    _parseTimestampToDateTime(application['appliedAt']);
                final bool isShortlisted =
                    application['status']?.toString() == 'shortlisted';
                final String coverLetter =
                    application['coverLetter']?.toString() ??
                        'No cover letter provided.';
                final double similarityScore =
                    (application['similarityScore'] as num?)?.toDouble() ?? 0.0;

                return Card(
                  key: ValueKey(applicationId),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF5F6FA),
                          radius: 22,
                          child: Text(
                            applicantName.isNotEmpty
                                ? applicantName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: const Color(0xFF4B5EFC),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applicantName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF4B5EFC)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                applicantEmail,
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Applied: ${_formatDateSince(appliedAt)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic),
                              ),
                              Text(
                                'Similarity: ${similarityScore.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _toggleShortlistStatus(
                              applicationId, isShortlisted),
                          icon: Icon(
                            isShortlisted ? Icons.star : Icons.star_border,
                            color: isShortlisted
                                ? Colors.white
                                : const Color(0xFF4B5EFC),
                            size: 18,
                          ),
                          label: Text(
                            isShortlisted ? 'Shortlisted' : 'Shortlist',
                            style: TextStyle(
                              color: isShortlisted
                                  ? Colors.white
                                  : const Color(0xFF4B5EFC),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isShortlisted
                                ? const Color(0xFF4B5EFC)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: isShortlisted
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: const Color(0xFF4B5EFC), width: 1),
                            ),
                            elevation: isShortlisted ? 2 : 1,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(
                          height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cover Letter:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF4B5EFC),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              coverLetter,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
