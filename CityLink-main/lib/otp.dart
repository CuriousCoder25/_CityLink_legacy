import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MyOtp extends StatefulWidget {
  const MyOtp({super.key});

  @override
  State<MyOtp> createState() => _MyOtpState();
}

class _MyOtpState extends State<MyOtp> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isSuccess = false;

  // Renamed the function to displaySnackBar
  void displaySnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyOtp(String verificationId, String phoneNumber) async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      displaySnackBar('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otp);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        _navigateBasedOnUser(userCredential.user!, phoneNumber);
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      displaySnackBar('Invalid OTP: $e');
    }
  }

Future<void> _navigateBasedOnUser(User user, String phoneNumber) async {
  const String fixedMunicipalityId = "1234567";

  if (await _checkUserExists(user.uid)) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    Position? userPosition = await _getUserLocation();
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'phone_number': phoneNumber,
      'municipality_id': fixedMunicipalityId, // Link the user to the fixed municipality
      'location': userPosition != null
          ? GeoPoint(userPosition.latitude, userPosition.longitude)
          : null,
      'created_at': Timestamp.now(),
    });

    setState(() {
      _isVerifying = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacementNamed(context, '/user_detail', arguments: {
      'userId': user.uid,
      'phoneNumber': phoneNumber,
      'detectedMunicipality': fixedMunicipalityId,
    });
  }
}

  Future<bool> _checkUserExists(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.setLanguageCode('en'); // Set to desired locale

    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final String verificationId = args['verificationId'];
    final String phoneNumber = args['phoneNumber'];

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: _isSuccess
          ? Center(child: Lottie.asset('assets/success.json', width: 200, height: 200))
          : _isVerifying
              ? const Center(child: CircularProgressIndicator())
              : _buildOtpForm(verificationId, phoneNumber),
    );
  }

  Widget _buildOtpForm(String verificationId, String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/img1.png', width: 150, height: 150),
          const SizedBox(height: 25),
          const Text('Enter OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Enter the OTP sent to your phone',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildOtpField(index)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _verifyOtp(verificationId, phoneNumber),
            child: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index].unfocus();
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index].unfocus();
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
  Future<Position?> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      displaySnackBar('Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        displaySnackBar('Location permissions are denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      displaySnackBar('Location permissions are permanently denied.');
      return null;
    }

    Position position = await Geolocator.getCurrentPosition();
    print('User Position: Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    return position;
  }

  Future<String?> _findMunicipality(double lat, double lon) async {
    try {
      // Fetch all municipalities
      final municipalities = await FirebaseFirestore.instance.collection('Municipalities').get();

      // Iterate through each municipality
      for (var doc in municipalities.docs) {
        final data = doc.data();

        // Check if the 'boundary' field exists and is a valid list
        if (data['boundary'] == null || data['boundary'] is! List) {
          print('Invalid or missing boundary for document: ${doc.id}');
          continue;
        }

        final List<dynamic> polygon = data['boundary'];

        // Log the polygon data for debugging
        print('Checking polygon for ${data['municipality_name']}: $polygon');

        // Ensure polygon has at least 3 points
        if (polygon.length < 3) {
          print('Polygon has insufficient points: ${doc.id}');
          continue;
        }

        // Validate each point in the polygon
        if (polygon.any((point) => point['latitude'] == null || point['longitude'] == null)) {
          print('Polygon contains invalid points in document: ${doc.id}');
          continue;
        }

        // Check if the user's position is inside the polygon
        if (_isPointInPolygon(lat, lon, polygon)) {
          print('User is inside the polygon of municipality: ${data['municipality_name']}');
          return data['municipality_name'] ?? 'Unknown Municipality';
        }
      }
    } catch (e) {
      print('Error in _findMunicipality: $e');
    }

    // If no municipality is found
    print('User is not inside any municipality.');
    return null;
  }




  bool _isPointInPolygon(double lat, double lon, List<dynamic> polygon) {
    int intersectCount = 0;

    for (int i = 0; i < polygon.length; i++) {
      final LatLng vertA = LatLng(polygon[i]['latitude'], polygon[i]['longitude']);
      final LatLng vertB = LatLng(
        polygon[(i + 1) % polygon.length]['latitude'],
        polygon[(i + 1) % polygon.length]['longitude'],
      );

      if (_rayCastIntersect(LatLng(lat, lon), vertA, vertB)) {
        intersectCount++;
      }
    }

    // Return true if the point is inside the polygon (odd intersections)
    final isInside = (intersectCount % 2) == 1;
    print('Point $lat, $lon is inside polygon: $isInside (Intersections: $intersectCount)');
    return isInside;
  }


  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double px = point.longitude;
    double py = point.latitude;
    double ax = vertA.longitude;
    double ay = vertA.latitude;
    double bx = vertB.longitude;
    double by = vertB.latitude;

    if ((ay > py && by > py) || (ay < py && by < py) || (ax < px && bx < px)) {
      return false;
    }

    if (ax == bx) {
      return px < ax; // Vertical line check
    }

    double slope = (by - ay) / (bx - ax);
    double intersectX = (py - ay) / slope + ax;

    return px < intersectX;
  }
}
