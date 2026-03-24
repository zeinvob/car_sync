import 'package:flutter/material.dart';
class JobCard extends StatelessWidget {
  final Map<String, dynamic> jobData;
  final String documentId;
  final VoidCallback onStatusUpdate;
  final VoidCallback onCameraTap;

  const JobCard({
    super.key,
    required this.jobData,
    required this.documentId,
    required this.onStatusUpdate,
    required this.onCameraTap,
  });


