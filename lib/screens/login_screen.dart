import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <--- ده السطر المهم جداً
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _myBox = Hive.box('expense_database');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isLoading = false;
  String _errorMessage = '';

// --- دالة الدخول بجوجل ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser != null) {
        // 1. هنا كان الخطأ، أضفنا await
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // 2. الآن الأخطاء هنا ستختفي تلقائياً لأن googleAuth أصبح بيانات صحيحة
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        
        _myBox.put('user_name', googleUser.displayName);
        _myBox.put('user_email', googleUser.email);
        _myBox.put('user_image', googleUser.photoUrl);

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Google sign in failed: $e");
    }
    setState(() => _isLoading = false);
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'Please enter your email to reset password.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() => _errorMessage = 'Check your email! Reset link sent 📧');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      if (_isLoginMode) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
        _myBox.put('user_email', email);
        _myBox.deleteAll(['user_image', 'user_name', 'first_name', 'last_name', 'phone_number']);
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'An error occurred');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1F1F1F), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.wallet, size: 80, color: Color(0xFFBB86FC)),
                const SizedBox(height: 20),
                Text(_isLoginMode ? 'Welcome Back' : 'Create Account', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
            
                TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(prefixIcon: const Icon(Icons.email, color: Color(0xFFBB86FC)), hintText: 'Email', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 20),
                TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(prefixIcon: const Icon(Icons.lock, color: Color(0xFFBB86FC)), hintText: 'Password', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                
                if (_isLoginMode)
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _resetPassword, child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70)))),

                if (_errorMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC)), child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(_isLoginMode ? 'LOGIN' : 'SIGN UP', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                
                const SizedBox(height: 20),
                const Row(children: [Expanded(child: Divider(color: Colors.grey)), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.grey))]),
                const SizedBox(height: 20),

                // زر جوجل
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    icon: Image.network('https://cdn-icons-png.flaticon.com/512/300/300221.png', height: 24),
                    label: const Text("Continue with Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 30),
                TextButton(onPressed: () => setState(() { _isLoginMode = !_isLoginMode; _errorMessage = ''; }), child: Text(_isLoginMode ? "New here? Create Account" : "Have an account? Login", style: const TextStyle(color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}