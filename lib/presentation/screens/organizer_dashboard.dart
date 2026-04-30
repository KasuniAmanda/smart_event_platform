import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Required
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/organizer_provider.dart'; // ✅ Import your new provider
import 'qr_scanner_screen.dart';
import 'event_attendees_screen.dart';

class OrganizerDashboard extends ConsumerWidget { // ✅ Changed to ConsumerWidget
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // ✅ Added WidgetRef
    final user = FirebaseAuth.instance.currentUser;
    // ✅ Watch the stream provider for real-time updates
    final eventsAsync = ref.watch(organizerEventsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Organizer Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDashboardHeader(user?.email ?? "Organizer"),
          Expanded(
            child: eventsAsync.when(
              data: (docs) => docs.isEmpty 
                  ? _buildEmptyState() 
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 80),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildEventCard(context, ref, docs[index].id, data);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
              error: (err, stack) => Center(child: Text("Error loading events: $err")),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context, ref),
        label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  // --- UI Components ---

  Widget _buildEventCard(BuildContext context, WidgetRef ref, String eventId, Map<String, dynamic> data) {
    DateTime date = (data['date'] as Timestamp).toDate();
    int total = data['totalSeats'] ?? 0;
    int available = data['availableSeats'] ?? 0;
    int booked = total - available;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(data['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, ref, eventId, data['title']),
              ),
            ],
          ),
          Text("📅 ${DateFormat('MMM dd, yyyy • hh:mm a').format(date)}", 
               style: TextStyle(color: Colors.indigo[400], fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSeatStat("Capacity", total.toString(), Colors.blue),
              _buildSeatStat("Confirmed", booked.toString(), Colors.orange),
              _buildSeatStat("Available", available.toString(), Colors.green),
            ],
          ),
          const Divider(height: 24),
          _buildCheckInProgress(eventId, booked),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => EventAttendeesScreen(eventId: eventId, eventTitle: data['title'])
              )),
              child: const Text("View Full Attendee List", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // Separate Widget for the Check-in Progress logic
  Widget _buildCheckInProgress(String eventId, int booked) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snapshot) {
        int scanned = 0;
        if (snapshot.hasData) {
          scanned = snapshot.data!.docs.where((doc) => 
            (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() == 'scanned'
          ).length;
        }
        double progress = booked > 0 ? scanned / booked : 0.0;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Check-in Progress", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8, color: Colors.green, backgroundColor: Colors.grey[200]),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final seatsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Event Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildValidatedField(controller: titleController, label: 'Event Title', icon: Icons.title),
                  const SizedBox(height: 12),
                  _buildValidatedField(controller: locationController, label: 'Location', icon: Icons.location_on),
                  const SizedBox(height: 12),
                  _buildValidatedField(controller: seatsController, label: 'Capacity', icon: Icons.people, isNumber: true),
                  // ... Date Picker Trigger ...
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // ✅ CALLING THE LOGIC LAYER (Member 2 requirement)
                  await ref.read(organizerLogicProvider).createEvent(
                    title: titleController.text,
                    location: locationController.text,
                    capacity: int.parse(seatsController.text),
                    date: selectedDateTime,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Publish Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String eventId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: Text("Are you sure you want to delete '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // ✅ CALLING THE LOGIC LAYER
              await ref.read(organizerLogicProvider).deleteEvent(eventId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildDashboardHeader(String email) => Container(/* ... existing style ... */);
  Widget _buildSeatStat(String l, String v, Color c) => Column(/* ... existing style ... */);
  Widget _buildEmptyState() => const Center(child: Text("No events found"));
  Widget _buildValidatedField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}