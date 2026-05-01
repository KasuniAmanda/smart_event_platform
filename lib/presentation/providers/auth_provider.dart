// ============================================================
// File: auth_provider.dart
// Assigned to: Member 2 (State Management & Business Logic)
// ============================================================


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/auth_service.dart';

// AUTH SERVICE
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// AUTH STATE (STABLE STREAM)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});