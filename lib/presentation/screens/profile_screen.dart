import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'my_tickets_screen.dart'; // ✅ Added for navigation

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    // Watching the userRoleProvider to display 'Attendee' or 'Organizer'
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 👤 Header Section with User Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.indigo),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? "User Email",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                roleAsync.when(
                  data: (role) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 🛠️ Professional Menu Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                _buildProfileOption(
                  context: context,
                  icon: Icons.confirmation_number_outlined,
                  title: "My Booking History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyTicketsScreen()),
                    );
                  },
                ),
                _buildProfileOption(
                  context: context,
                  icon: Icons.security_rounded,
                  title: "Account Security",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Security settings coming soon!")),
                    );
                  },
                ),
                _buildProfileOption(
                  context: context,
                  icon: Icons.help_center_outlined,
                  title: "Support & Help",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Contact support at help@smartevent.com")),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // 🚪 Danger Zone: Logout
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Colors.red, width: 1.5),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Helper Widget for the Menu List
  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon, 
    required String title, 
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.indigo),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}