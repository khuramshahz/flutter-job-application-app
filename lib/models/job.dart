class Job {
  final String title;
  final String company;
  final String location;
  final String salary;
  final String jobType;
  final String description;
  final String requirements;
  final DateTime postedAt;
  final String employerId;
  final List<String> skills;

  // New analytics fields
  final int views;
  final int totalApplicants;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.description,
    required this.requirements,
    required this.postedAt,
    required this.employerId,
    required this.skills,
    this.views = 0,
    this.totalApplicants = 0,
  });

  factory Job.fromJson(Map<dynamic, dynamic> json) {
    return Job(
      title: json['title']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      salary: json['salary']?.toString() ?? '',
      jobType: json['jobType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      postedAt: _parsePostedAt(json['postedAt']),
      skills: _parseSkills(json['skills']),
      views: _parseInt(json['views']),
      totalApplicants: _parseInt(json['totalApplicants']),
    );
  }

  static DateTime _parsePostedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static List<String> _parseSkills(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
