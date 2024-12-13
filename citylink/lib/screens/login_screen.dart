import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MunicipalitySignUpScreen extends StatefulWidget {
  @override
  _MunicipalitySignUpScreenState createState() => _MunicipalitySignUpScreenState();
}

class _MunicipalitySignUpScreenState extends State<MunicipalitySignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _municipalityNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _zoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _emailController = TextEditingController();
  final _itOfficerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle the sign-up process
  Future<void> _registerMunicipality() async {
    if (!_formKey.currentState!.validate()) return; // Validate form fields

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      // Create a new user with Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Send an email verification
      await userCredential.user!.sendEmailVerification();

      // Add municipality details to Firestore
      await _firestore.collection('municipalities').doc(userCredential.user!.uid).set({
        'municipalityName': _municipalityNameController.text,
        'district': _districtController.text,
        'zone': _zoneController.text,
        'province': _provinceController.text,
        'itOfficerName': _itOfficerNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'createdAt': Timestamp.now(),
      });

      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Please verify your email.')),
      );

      // Redirect to the Login Screen after successful registration
      Navigator.pushReplacementNamed(context, '/login'); // Or go to login screen

    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Municipality Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Municipality Name
              TextFormField(
                controller: _municipalityNameController,
                decoration: InputDecoration(
                  labelText: 'Municipality Name',
                  hintText: 'Enter municipality name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter municipality name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // District
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  hintText: 'Enter district',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter district';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Zone
              TextFormField(
                controller: _zoneController,
                decoration: InputDecoration(
                  labelText: 'Zone',
                  hintText: 'Enter zone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter zone';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Province
              TextFormField(
                controller: _provinceController,
                decoration: InputDecoration(
                  labelText: 'Province',
                  hintText: 'Enter province',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter province';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // IT Officer Name
              TextFormField(
                controller: _itOfficerNameController,
                decoration: InputDecoration(
                  labelText: 'IT Officer Name',
                  hintText: 'Enter IT Officer name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IT Officer name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password should be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),

              // Loading Indicator or Register Button
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerMunicipality,
                      child: Text('Register Municipality'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
