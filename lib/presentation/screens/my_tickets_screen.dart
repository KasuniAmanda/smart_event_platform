import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; // ✅ Added for date formatting
import '../../data/datasources/booking_service.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  void _confirmCancellation(BuildContext context, String ticketId, String eventId, String eventTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking?"),
        content: Text("Are you sure you want to cancel your spot for '$eventTitle'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Ticket"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await BookingService().cancelBooking(
                ticketId: ticketId,
                eventId: eventId,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ticket cancelled successfully.")),
                );
              }
            },
            child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100], // ✅ Light grey background
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          final tickets = snapshot.data!.docs;

          if (tickets.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticketDoc = tickets[index];
              final ticket = ticketDoc.data() as Map<String, dynamic>;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('events').doc(ticket['eventId']).get(),
                builder: (context, eventSnapshot) {
                  if (!eventSnapshot.hasData) return const SizedBox.shrink();
                  
                  final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
                  final bool canCancel = ticket['status'] == 'valid';
                  final DateTime eventDate = (eventData['date'] as Timestamp).toDate();
                  final String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(eventDate);

                  return _buildTicketCard(context, ticket, eventData, ticketDoc.id, formattedDate, canCancel);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Professional Ticket UI Design
  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket, Map<String, dynamic> eventData, String docId, String date, bool canCancel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(ticket['status']),
                      const SizedBox(height: 12),
                      Text(
                        eventData['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(eventData['location'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                // QR Button
                GestureDetector(
                  onTap: () => _showQRCode(context, ticket['ticketId']),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.indigo, size: 40),
                  ),
                ),
              ],
            ),
          ),
          
          if (canCancel) ...[
            const Divider(height: 1),
            TextButton(
              onPressed: () => _confirmCancellation(context, docId, ticket['eventId'], eventData['title']),
              child: const Text("CANCEL BOOKING", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Status Pill Badge
  Widget _buildStatusBadge(String status) {
    bool isValid = status == 'valid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isValid ? Colors.green.shade700 : Colors.indigo.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No active tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("Events you book will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showQRCode(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(child: Text("Scan for Entry", style: TextStyle(fontWeight: FontWeight.bold))),
        content: SizedBox(
          height: 220, width: 220,
          child: Center(
            child: QrImageView(
              data: ticketId,
              version: QrVersions.auto,
              size: 200.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.indigo),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.indigo),
            ),
          ),
        ),
      ),
    );
  }
}