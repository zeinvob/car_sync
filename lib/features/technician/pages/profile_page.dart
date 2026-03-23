import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:car_sync/features/auth/pages/login_page.dart';

// ============================================================================
// 1. THE MAIN PROFILE PAGE
// ============================================================================
class TechnicianProfilePage extends StatelessWidget {
  const TechnicianProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User data not found"));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final fullName = userData['fullName'] ?? 'Technician';
                final email = userData['email'] ?? user.email ?? '';
                final profileImageUrl = userData['profileImageUrl'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- PROFILE HEADER ---
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                        child: profileImageUrl.isEmpty 
                            ? const Icon(Icons.person, size: 50, color: Colors.blueAccent) 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 40),

                      // --- EDIT PROFILE BUTTON ---
                      _buildMenuCard([
                        _buildListTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TechnicianEditProfilePage(
                                  userId: user.uid,
                                  userData: userData,
                                ),
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 40),

                      // --- SIGN OUT BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: Text(
                            "Sign Out",
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A1A1A)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap, 
    );
  }
}

// ============================================================================
// 2. THE EDIT PROFILE PAGE 
// ============================================================================
class TechnicianEditProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const TechnicianEditProfilePage({super.key, required this.userId, required this.userData});

  @override
  State<TechnicianEditProfilePage> createState() => _TechnicianEditProfilePageState();
}

class _TechnicianEditProfilePageState extends State<TechnicianEditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['fullName'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');

    if (widget.userData['dateOfBirth'] != null) {
      if (widget.userData['dateOfBirth'] is Timestamp) {
        _selectedDate = (widget.userData['dateOfBirth'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> updates = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedDate != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email = widget.userData['email'] ?? '';
    final String profileImageUrl = widget.userData['profileImageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EDITABLE PROFILE PICTURE ---
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.blueAccent) : null,
                  ),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF2B3A55), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: IconButton(
                      onPressed: () => _showEditPhotoOptions(context, widget.userId, profileImageUrl),
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- FULL NAME ---
            Text("Full Name", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 8),
            _buildTextField(controller: _nameController, icon: Icons.person_outline, hint: "Enter your name"),
            const SizedBox(height: 20),

            // --- PHONE NUMBER ---
            Text("Phone Number", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 8),
            _buildTextField(controller: _phoneController, icon: Icons.phone_outlined, hint: "Enter phone number", isNumber: true),
            const SizedBox(height: 20),

            // --- DATE OF BIRTH ---
            Text("Date of Birth", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null ? "Select Date" : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: GoogleFonts.poppins(fontSize: 16, color: _selectedDate == null ? Colors.grey : Colors.black),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- EMAIL (DISABLED) ---
            Text("Email", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Text(email, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                  const Spacer(),
                  Icon(Icons.lock_outline, color: Colors.grey[400]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text("Email cannot be changed", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            ),
            const SizedBox(height: 40),

            // --- SAVE CHANGES BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B3A55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Save Changes", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required IconData icon, required String hint, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }

  // --- PHOTO UPLOAD LOGIC ---
  void _showEditPhotoOptions(BuildContext context, String userId, String currentImageUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () { Navigator.pop(context); _pickAndUploadImage(context, userId, ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () { Navigator.pop(context); _pickAndUploadImage(context, userId, ImageSource.camera); },
              ),
              if (currentImageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("Remove Photo", style: TextStyle(color: Colors.redAccent)),
                  onTap: () { Navigator.pop(context); _removeProfileImage(context, userId); },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, String userId, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
    if (image == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final File file = File(image.path);
      final storageRef = FirebaseStorage.instance.ref().child('users').child(userId).child('profile.jpg');
      await storageRef.putFile(file);
      final String downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'profileImageUrl': downloadUrl});
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _removeProfileImage(BuildContext context, String userId) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users').child(userId).child('profile.jpg');
      await storageRef.delete().catchError((_) {});
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'profileImageUrl': FieldValue.delete()});
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed.")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}