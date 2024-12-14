import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatefulWidget {
  final String municipalityId;

  const UserDetailsScreen({super.key, required this.municipalityId});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _firstName, _lastName, _email, _citizenshipNumber;
  bool _isSaving = false;
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String? phoneNumber = arguments['phoneNumber'];

    if (phoneNumber != null) {
      _phoneNumberController.text = phoneNumber;
    }
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if the form is invalid
    }
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      // Assuming you have the user's UID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      final userDetails = {
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
        'phone_number': _phoneNumberController.text, // Use the phone number controller
        'citizenship_number': _citizenshipNumber,
        'created_at': Timestamp.now(),
      };

      // Save user details in the "Users" subcollection under the municipality ID
      await FirebaseFirestore.instance
          .collection('Municipalities')
          .doc(widget.municipalityId) // Use the passed municipality ID
          .collection('Users')
          .doc(userId) // Use UID as the document ID
          .set(userDetails); // Use `set` instead of `add`

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details saved successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/dashboard'); // Navigate to the dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving user details: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details' ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your details:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onSaved: (value) => _firstName = value,
                  validator: (value) =>
                  value!.isEmpty ? 'First name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onSaved: (value) => _lastName = value,
                  validator: (value) =>
                  value!.isEmpty ? 'Last name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Citizenship Number'),
                  onSaved: (value) => _citizenshipNumber = value,
                  validator: (value) => value!.isEmpty
                      ? 'Citizenship number is required'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSaved: (value) => _email = value,
                  validator: (value) {
                    if (value!.isNotEmpty &&
                        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) =>
                  value!.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 20),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveUserDetails,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Details',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
