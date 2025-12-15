import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _myBox = Hive.box('expense_database');
  final _auth = FirebaseAuth.instance;

  final _displayNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = '';
  String? _tempImage;

  // القائمة الكاملة للأفاتارز (11 شكل) كما طلبت
  final List<String> _avatarList = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Lilly',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Jack',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Molly',
    'https://api.dicebear.com/7.x/bottts/png?seed=Sudo',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Zoey',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Happy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Nolan',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Jessica',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Ryan',
    'https://api.dicebear.com/7.x/bottts/png?seed=Gizmo',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Abby',
  ];

  @override
  void initState() {
    super.initState();
    _email = _auth.currentUser?.email ?? _myBox.get('user_email') ?? 'User';
    _displayNameController.text = _myBox.get('user_name') ?? '';
    _firstNameController.text = _myBox.get('first_name') ?? '';
    _lastNameController.text = _myBox.get('last_name') ?? '';
    _phoneController.text = _myBox.get('phone_number') ?? '';
    _tempImage = _myBox.get('user_image');
  }

  // --- دالة تغيير الباسورد (مع حل مشكلة الأمان) ---
  void _changePassword() {
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: newPassController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new password',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password too short!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _auth.currentUser!.updatePassword(newPassController.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password Updated Successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) Navigator.pop(ctx);

                // الحل الذكي للمشكلة: لو طلب تسجيل دخول حديث
                if (e.code == 'requires-recent-login') {
                  _showReLoginDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.message}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
            ),
            child: const Text("Update", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // نافذة تطلب من المستخدم إعادة الدخول
  void _showReLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Security Alert 🔒",
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          "For your security, you need to log in again before changing your password.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pop(ctx); // close dialog
                // الذهاب لصفحة الدخول
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              "Log Out & Login",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (_tempImage == null)
      return const NetworkImage(
        'https://api.dicebear.com/7.x/initials/png?seed=User',
      );
    if (_tempImage!.startsWith('http')) return NetworkImage(_tempImage!);
    return MemoryImage(base64Decode(_tempImage!));
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      setState(() => _tempImage = base64Encode(imageBytes));
    }
  }

  void _saveProfile() {
    if (_displayNameController.text.isNotEmpty)
      _myBox.put('user_name', _displayNameController.text);
    if (_firstNameController.text.isNotEmpty)
      _myBox.put('first_name', _firstNameController.text);
    if (_lastNameController.text.isNotEmpty)
      _myBox.put('last_name', _lastNameController.text);
    if (_phoneController.text.isNotEmpty)
      _myBox.put('phone_number', _phoneController.text);
    if (_tempImage != null) _myBox.put('user_image', _tempImage);

    _auth.currentUser?.updateDisplayName(_displayNameController.text);

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile Saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBB86FC),
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: _getImageProvider(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF03DAC6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // قائمة الأفاتارز الكاملة
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _tempImage = _avatarList[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2C2C2C),
                        backgroundImage: NetworkImage(_avatarList[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_reset, color: Colors.redAccent),
                label: const Text(
                  "Change Password",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),

            const SizedBox(height: 10),
            _buildTextField(
              "Display Name",
              Icons.badge,
              _displayNameController,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "First Name",
                    Icons.person,
                    _firstNameController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    "Last Name",
                    Icons.person,
                    _lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Phone",
              Icons.phone,
              _phoneController,
              isNumber: true,
            ),
            const SizedBox(height: 15),

            TextField(
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: _email,
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                ),
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF03DAC6)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
