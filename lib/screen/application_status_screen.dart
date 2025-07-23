import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ApplicationStatusScreen extends StatelessWidget {
  final String jobTitle;
  final String status;

  const ApplicationStatusScreen({
    super.key,
    required this.jobTitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String animationAsset;
    String statusMessage;
    Color messageColor;

    if (status.toLowerCase() == 'shortlisted') {
      animationAsset =
          'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json';
      statusMessage =
          'Congratulations! You have been shortlisted for the "$jobTitle" position!';
      messageColor = Colors.green.shade700;
    } else {
      animationAsset =
          'https://assets2.lottiefiles.com/packages/lf20_mjlh3hcy.json';
      statusMessage =
          'Your application is currently pending review. Please wait for an update.';
      messageColor = Colors.orange.shade700;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Application Status",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4B5EFC),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.network(
                animationAsset,
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  print('Lottie loading error: $error');
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load animation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      Text(
                        'Check internet or Lottie URL.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.red.shade500, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: messageColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
