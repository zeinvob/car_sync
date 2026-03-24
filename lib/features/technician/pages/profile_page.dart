import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:car_sync/features/auth/pages/login_page.dart';
import 'package:car_sync/core/constants/app_colors.dart';

/// ================= PROFILE PAGE =================
class TechnicianProfilePage extends StatelessWidget {
  const TechnicianProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final name = data['fullName'] ?? 'Technician';
                final email = data['email'] ?? user.email ?? '';
                final image = data['profileImageUrl'] ?? '';

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// PROFILE IMAGE (VIEW ONLY)
                      CircleAvatar(
                        radius: 55,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                        backgroundImage:
                            image.isNotEmpty ? NetworkImage(image) : null,
                        child: image.isEmpty
                            ? const Icon(Icons.person, size: 55)
                            : null,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        email,
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      /// EDIT PROFILE
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TechnicianEditProfilePage(
                                  userId: user.uid,
                                  userData: data,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "Edit Profile",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// LOGOUT
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// ================= EDIT PROFILE =================
class TechnicianEditProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const TechnicianEditProfilePage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<TechnicianEditProfilePage> createState() =>
      _TechnicianEditProfilePageState();
}

class _TechnicianEditProfilePageState
    extends State<TechnicianEditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.userData['fullName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userData['phone'] ?? '');

    if (widget.userData['dateOfBirth'] is Timestamp) {
      _selectedDate =
          (widget.userData['dateOfBirth'] as Timestamp).toDate();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dateOfBirth': _selectedDate != null
          ? Timestamp.fromDate(_selectedDate!)
          : null,
    });

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),

            ListTile(
              title: Text(_selectedDate == null
                  ? "Select Date"
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            TextField(
              enabled: false,
              controller: TextEditingController(text: email),
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}