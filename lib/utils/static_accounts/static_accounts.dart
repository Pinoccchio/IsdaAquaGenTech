import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaticAccounts {
  static Future<void> initializeAdminAccount() async {
    const String email = 'isda.mobileapp@gmail.com';
    const String password = 'ISDAmobapp_1219';
    const String firstName = 'MARIO';
    const String middleName = 'JUAN';
    const String lastName = 'ANDRES';

    try {
      // Check if the admin account already exists in Firestore
      final QuerySnapshot adminQuery = await FirebaseFirestore.instance
          .collection('USERS')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        // Admin account doesn't exist, create it
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance.collection('USERS').doc(userCredential.user!.uid).set({
            'email': email,
            'role': 'admin',
            'firstName': firstName,
            'middleName': middleName,
            'lastName': lastName,
            'displayName': '$firstName $middleName $lastName',
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Admin account created successfully');
        }
      } else {
        print('Admin account already exists');
      }
    } on FirebaseAuthException catch (e) {
      print('Error creating admin account: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
}




