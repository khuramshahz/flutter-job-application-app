import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/job.dart';

class JobPostScreen extends StatefulWidget {
  const JobPostScreen({super.key});

  @override
  _JobPostScreenState createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final salaryController = TextEditingController();
  final descriptionController = TextEditingController();
  final requirementsController = TextEditingController();
  final skillsController = TextEditingController();

  String selectedJobType = 'Full-time';
  bool _isPosting = false;

  @override
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    locationController.dispose();
    salaryController.dispose();
    descriptionController.dispose();
    requirementsController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void postJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isPosting = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showSnackBar("You must be logged in to post a job.", isError: true);
        setState(() {
          _isPosting = false;
        });
        return;
      }

      List<String> skills = skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      try {
        final newJob = Job(
          title: titleController.text,
          company: companyController.text,
          location: locationController.text,
          salary: salaryController.text,
          jobType: selectedJobType,
          description: descriptionController.text,
          requirements: requirementsController.text,
          postedAt: DateTime.now(),
          skills: skills,
          employerId: currentUser.uid,
          views: 0,
          totalApplicants: 0,
        );

        final dbRef = FirebaseDatabase.instance.ref().child('jobs').push();

        await dbRef.set({
          'title': newJob.title,
          'company': newJob.company,
          'location': newJob.location,
          'salary': newJob.salary,
          'jobType': newJob.jobType,
          'description': newJob.description,
          'requirements': newJob.requirements,
          'postedAt': newJob.postedAt.millisecondsSinceEpoch,
          'skills': newJob.skills,
          'employerId': newJob.employerId,
          'views': newJob.views,
          'totalApplicants': newJob.totalApplicants,
        });

        _showSnackBar("Job posted successfully!");

        titleController.clear();
        companyController.clear();
        locationController.clear();
        salaryController.clear();
        descriptionController.clear();
        requirementsController.clear();
        skillsController.clear();
        setState(() {
          selectedJobType = 'Full-time';
        });
      } catch (e) {
        print("Error posting job: $e");
        _showSnackBar("Failed to post job. Please try again.", isError: true);
      } finally {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF4B5EFC)),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4B5EFC), width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _buildInputDecoration(label, hint),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildJobTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedJobType,
        decoration: _buildInputDecoration('Job Type'),
        items: ['Full-time', 'Part-time', 'Remote', 'Contract']
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedJobType = value;
            });
          }
        },
        validator: (value) => value == null ? 'Please select a job type' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Post a New Job',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4B5EFC),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Job Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5EFC),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: titleController,
                  label: 'Job Title',
                  hint: 'e.g., Senior Flutter Developer',
                ),
                _buildTextField(
                  controller: companyController,
                  label: 'Company Name',
                  hint: 'e.g., Tech Solutions Inc.',
                ),
                _buildTextField(
                  controller: locationController,
                  label: 'Job Location',
                  hint: 'e.g., New York, Remote',
                ),
                _buildTextField(
                  controller: salaryController,
                  label: 'Salary (per annum)',
                  hint: 'e.g., \$70,000 - \$90,000',
                  keyboardType: TextInputType.text,
                ),
                _buildJobTypeDropdown(),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Job Description',
                  hint: 'Provide a comprehensive overview of the role...',
                  maxLines: 5,
                ),
                _buildTextField(
                  controller: requirementsController,
                  label: 'Key Requirements',
                  hint:
                      'List essential skills and qualifications (e.g., 5+ years experience, Bachelor\'s degree)...',
                  maxLines: 5,
                ),
                _buildTextField(
                  controller: skillsController,
                  label: 'Required Skills (comma-separated)',
                  hint: 'e.g., Flutter, Dart, Firebase, REST APIs',
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : postJob,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Color(0xFF4B5EFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Post Job',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
