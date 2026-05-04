import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //  REGISTER
  Future<UserCredential> registerUser(
      String email, String password, String role) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return res;
    } catch (e) {
      rethrow;
    }
  }

  //  LOGIN
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //  LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //  FIXED ROLE FETCH (IMPORTANT)
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) return 'attendee';

      final data = doc.data();

      if (data == null || !data.containsKey('role')) {
        return 'attendee';
      }

      return data['role'] ?? 'attendee';
    } catch (e) {
      return 'attendee'; // fallback prevents login loop
    }
  }
}