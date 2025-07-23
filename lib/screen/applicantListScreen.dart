import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:statefulclickcounter/screen/job_applicants_detail_screen.dart';
import 'package:statefulclickcounter/screen/EmployerDashboard.dart';

class ApplicantListScreen extends StatefulWidget {
  const ApplicantListScreen({super.key});

  @override
  State<ApplicantListScreen> createState() => _ApplicantListScreenState();
}

class _ApplicantListScreenState extends State<ApplicantListScreen> {
  late Future<List<Map<String, dynamic>>> _jobsWithApplicantsFuture;

  final databaseRef = FirebaseDatabase.instance.ref();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _jobsWithApplicantsFuture = _fetchJobsAndApplicants();
  }

  DateTime _parseTimestampToDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  List<String> _parseSkills(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<List<Map<String, dynamic>>> _fetchJobsAndApplicants() async {
    if (currentUser == null) {
      return [];
    }

    final userId = currentUser!.uid;

    final jobsRef = databaseRef.child('jobs');
    final jobAppliedRef = databaseRef.child('jobApplied');
    final usersRef = databaseRef.child('users');

    List<Map<String, dynamic>> jobWithApplicantsList = [];

    try {
      final jobsSnapshot =
          await jobsRef.orderByChild('employerId').equalTo(userId).get();

      if (!jobsSnapshot.exists || jobsSnapshot.value == null) {
        return [];
      }

      final Map<String, dynamic> allEmployerJobsData =
          Map<String, dynamic>.from(jobsSnapshot.value as Map);

      List<Map<String, dynamic>> employerJobs = [];
      allEmployerJobsData.forEach((key, value) {
        if (value != null) {
          final jobMap = Map<String, dynamic>.from(value);
          employerJobs.add({'key': key, ...jobMap});
        }
      });

      employerJobs.sort((a, b) {
        DateTime postedA = _parseTimestampToDateTime(a['postedAt']);
        DateTime postedB = _parseTimestampToDateTime(b['postedAt']);
        return postedB.compareTo(postedA);
      });

      for (var jobMap in employerJobs) {
        final String jobKey = jobMap['key']?.toString() ?? '';

        List<Map<String, dynamic>> currentJobApplicants = [];

        final applicationsSnapshot =
            await jobAppliedRef.orderByChild('jobid').equalTo(jobKey).get();

        if (applicationsSnapshot.exists && applicationsSnapshot.value != null) {
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

                currentJobApplicants.add({
                  'application': {'id': appId, ...applicationMap},
                  'applicantDetails': applicantDetails,
                });
              } else {
                currentJobApplicants.add({
                  'application': {'id': appId, ...applicationMap},
                  'applicantDetails': {
                    'name': 'Unknown User (ID: $applicantUserId)',
                    'email': 'N/A'
                  },
                });
              }
            }
          }
          currentJobApplicants.sort((a, b) {
            DateTime appliedA =
                _parseTimestampToDateTime(a['application']['appliedAt']);
            DateTime appliedB =
                _parseTimestampToDateTime(b['application']['appliedAt']);
            return appliedB.compareTo(appliedA);
          });
        }

        jobMap['applicants'] = currentJobApplicants;
        jobWithApplicantsList.add(jobMap);
      }

      return jobWithApplicantsList;
    } catch (e) {
      print("Error fetching jobs and applicants: $e");
      return [];
    }
  }

  MaterialColor _getJobTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return Colors.green;
      case 'part-time':
        return Colors.orange;
      case 'contract':
        return Colors.blue;
      case 'remote':
        return Colors.purple;
      default:
        return Colors.grey;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmployerHomePage()),
            );
          },
        ),
        title: const Text(
          "Manage Applicants",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _jobsWithApplicantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B5EFC)),
            );
          }

          if (snapshot.hasError) {
            print("FutureBuilder Error: ${snapshot.error}");
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
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No jobs posted by you, or no applicants yet.",
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
                _jobsWithApplicantsFuture = _fetchJobsAndApplicants();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final jobMap = data[index];
                final String jobKey = jobMap['key']?.toString() ?? '';
                final List<Map<String, dynamic>> applicants =
                    List<Map<String, dynamic>>.from(jobMap['applicants'] ?? []);

                final String jobTitle = jobMap['title']?.toString() ?? 'N/A';
                final String companyName =
                    jobMap['company']?.toString() ?? 'N/A';
                final DateTime postedAt =
                    _parseTimestampToDateTime(jobMap['postedAt']);

                return Card(
                  key: ValueKey(jobKey),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    collapsedBackgroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      jobTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5EFC),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_alt_outlined,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${applicants.length} Applicants',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Posted: ${_formatDateSince(postedAt)}',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        JobApplicantsDetailScreen(
                                      jobKey: jobKey,
                                      jobTitle: jobTitle,
                                    ),
                                  ),
                                ).then((_) {
                                  setState(() {
                                    _jobsWithApplicantsFuture =
                                        _fetchJobsAndApplicants();
                                  });
                                });
                              },
                              icon: const Icon(Icons.person_add_alt_1,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Shortlist Candidates',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B5EFC),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(
                          height: 1, thickness: 1, indent: 16, endIndent: 16),
                      if (applicants.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No applicants for this job yet.',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade500,
                                fontSize: 12),
                          ),
                        )
                      else
                        ...applicants.map((applicantData) {
                          final Map<String, dynamic> application =
                              Map<String, dynamic>.from(
                                  applicantData['application'] ?? {});
                          final Map<String, dynamic> applicantDetails =
                              Map<String, dynamic>.from(
                                  applicantData['applicantDetails'] ?? {});

                          final String applicantName =
                              applicantDetails['name']?.toString() ??
                                  'Unknown Applicant';
                          final String applicantEmail =
                              applicantDetails['email']?.toString() ?? 'N/A';
                          final DateTime appliedAt = _parseTimestampToDateTime(
                              application['appliedAt']);
                          final String applicationStatus =
                              application['status']?.toString() ?? 'pending';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFF5F6FA),
                                  child: Text(
                                    applicantName.isNotEmpty
                                        ? applicantName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: const Color(0xFF4B5EFC),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        applicantName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        applicantEmail,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Applied: ${_formatDateSince(appliedAt)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic),
                                      ),
                                      Text(
                                        'Status: ${applicationStatus[0].toUpperCase()}${applicationStatus.substring(1)}',
                                        style: TextStyle(
                                          color:
                                              applicationStatus == 'shortlisted'
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (applicationStatus == 'shortlisted')
                                  Icon(Icons.star,
                                      color: Colors.amber.shade700, size: 20),
                              ],
                            ),
                          );
                        }).toList(),
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
