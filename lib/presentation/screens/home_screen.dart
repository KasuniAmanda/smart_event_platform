import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'organizer_dashboard.dart';
import 'attendee_feed.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watches the user role (Attendee vs Organizer) from Firestore
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        // 🛡️ Role-Based Routing Logic
        if (role == 'organizer') {
          return const OrganizerDashboard();
        } 
        
        // Default to Attendee Feed if role is 'attendee' or anything else
        return const AttendeeFeed();
      },
      // ✨ Professional Branded Loading State
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.indigo,
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                "Setting up your dashboard...",
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      // ⚠️ Professional Error Recovery State
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  "Configuration Error",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "We couldn't verify your user role. Please check your connection.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: () => ref.refresh(userRoleProvider), // ✅ Allow user to retry
                  child: const Text("Retry Connection", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}