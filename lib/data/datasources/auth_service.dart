import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential?> registerUser(String email, String password, String role) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'email': email,
        'role': role,
      });
      return res;
    } catch (e) { rethrow; }
  }

  Future<UserCredential?> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ADD THIS METHOD
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc['role'];
  }
}