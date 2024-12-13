import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _municipalityNameController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _itOfficerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerMunicipality() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Register user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Save Municipality details to Firestore
      await _firestore.collection('municipalities').doc(userCredential.user!.uid).set({
        'municipalityName': _municipalityNameController.text,
        'district': _districtController.text,
        'zone': _zoneController.text,
        'province': _provinceController.text,
        'itOfficerName': _itOfficerNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'createdAt': Timestamp.now(),
      });

      // After successful registration, navigate to the dashboard (or login)
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      // Handle errors, e.g., email already in use, weak password
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Municipality Sign-Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _municipalityNameController,
                decoration: const InputDecoration(labelText: 'Municipality Name'),
                validator: (value) => value!.isEmpty ? 'Please enter municipality name' : null,
              ),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (value) => value!.isEmpty ? 'Please enter district' : null,
              ),
              TextFormField(
                controller: _zoneController,
                decoration: const InputDecoration(labelText: 'Zone'),
                validator: (value) => value!.isEmpty ? 'Please enter zone' : null,
              ),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(labelText: 'Province'),
                validator: (value) => value!.isEmpty ? 'Please enter province' : null,
              ),
              TextFormField(
                controller: _itOfficerNameController,
                decoration: const InputDecoration(labelText: 'IT Officer Name'),
                validator: (value) => value!.isEmpty ? 'Please enter IT Officer name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Please enter email' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter phone number' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerMunicipality,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
