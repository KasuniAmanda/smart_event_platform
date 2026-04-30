import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

// Member 2: Listen to Auth Changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Member 2: Role Provider
final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 'guest';
  return await ref.read(authServiceProvider).getUserRole(user.uid);
});