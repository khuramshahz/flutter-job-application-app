import 'package:flutter/material.dart';
import '../models/job.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyForJobScreen extends StatefulWidget {
  final Job job;
  final String jobkey;

  const ApplyForJobScreen({super.key, required this.job, required this.jobkey});

  @override
  _ApplyForJobScreenState createState() => _ApplyForJobScreenState();
}

class _ApplyForJobScreenState extends State<ApplyForJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController expectedSalaryController =
      TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();

  String? selectedExperience = 'Fresh';

  @override
  void dispose() {
    nameController.dispose();
    portfolioController.dispose();
    emailController.dispose();
    phoneController.dispose();
    linkedinController.dispose();
    availabilityController.dispose();
    expectedSalaryController.dispose();
    educationController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF4B5EFC).withOpacity(0.6)),
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(color: Colors.black54),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4B5EFC), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  void submitApplication() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to apply.")),
        );
        return;
      }

      final application = {
        'userId': user.uid,
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'linkedin': linkedinController.text,
        'portfolio': portfolioController.text,
        'experience': selectedExperience,
        'availability': availabilityController.text,
        'expectedSalary': expectedSalaryController.text,
        'education': educationController.text,
        'coverLetter': coverLetterController.text,
        'company': widget.job.company,
        'employeeId': widget.job.employerId,
        'appliedAt': DateTime.now().toIso8601String(),
        'jobid': widget.jobkey,
      };

      try {
        final databaseRef = FirebaseDatabase.instance.ref("jobApplied");
        await databaseRef.push().set(application);

        final jobRef = FirebaseDatabase.instance
            .ref("jobs/${widget.jobkey}/totalApplicants");

        final currentCountSnapshot = await jobRef.get();
        int currentCount = 0;
        if (currentCountSnapshot.exists && currentCountSnapshot.value is int) {
          currentCount = currentCountSnapshot.value as int;
        }

        await jobRef.set(currentCount + 1);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('🎉 Application Submitted!',
                textAlign: TextAlign.center),
            content: Text(
              'You have successfully applied for the ${widget.job.title} position at ${widget.job.company}.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Text('OK',
                    style: TextStyle(color: Color(0xFF4B5EFC))),
              ),
            ],
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          selectedExperience = 'Fresh';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit application: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Apply for ${widget.job.title}',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 0,
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
                  'Submit Your Application',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill out the form below to apply for this position.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildFormSection('Personal Information', [
                  TextFormField(
                    controller: nameController,
                    decoration: buildInputDecoration('Full Name',
                        'Enter your full name', Icons.person_outline),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: buildInputDecoration('Email Address',
                        'Enter your email', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: buildInputDecoration('Phone Number',
                        'Enter your phone number', Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your phone number' : null,
                  ),
                ]),
                const SizedBox(height: 24),
                _buildFormSection('Professional Details', [
                  TextFormField(
                    controller: linkedinController,
                    decoration: buildInputDecoration('LinkedIn Profile',
                        'linkedin.com/in/yourprofile', Icons.link),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your LinkedIn URL' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: portfolioController,
                    decoration: buildInputDecoration('GitHub / Portfolio URL',
                        'github.com/yourprofile', Icons.code),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedExperience,
                    items: [
                      'Fresh',
                      '1-2 Years',
                      '3+ Years',
                      '5+ Years',
                      '10+ Years'
                    ].map((experience) {
                      return DropdownMenuItem<String>(
                        value: experience,
                        child: Text(experience),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedExperience = value;
                      });
                    },
                    decoration: buildInputDecoration('Experience Level',
                        'Select your experience', Icons.work_outline),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please select experience'
                        : null,
                  ),
                ]),
                const SizedBox(height: 24),
                _buildFormSection('Job-Specific Information', [
                  TextFormField(
                    controller: availabilityController,
                    decoration: buildInputDecoration(
                        'Availability',
                        'e.g., Immediately, 2 Weeks Notice',
                        Icons.event_available_outlined),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your availability' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: expectedSalaryController,
                    decoration: buildInputDecoration('Expected Salary (Annual)',
                        'e.g., \$50,000', Icons.attach_money_outlined),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: educationController,
                    decoration: buildInputDecoration(
                        'Highest Education',
                        'e.g., Bachelor\'s in Computer Science',
                        Icons.school_outlined),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildFormSection('Cover Letter', [
                  TextFormField(
                    controller: coverLetterController,
                    maxLines: 8,
                    decoration: buildInputDecoration(
                            'Cover Letter',
                            'Tell us why you are a great fit for this role...',
                            Icons.description_outlined)
                        .copyWith(
                      hintMaxLines: 3,
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter a cover letter' : null,
                  ),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitApplication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF4B5EFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Submit Application',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
