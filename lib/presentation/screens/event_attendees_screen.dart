import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ✅ For professional date formatting

class EventAttendeesScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventAttendeesScreen({
    super.key, 
    required this.eventId, 
    required this.eventTitle
  });

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('eventId', isEqualTo: widget.eventId)
            .orderBy('bookedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allTickets = snapshot.data!.docs;
          
          // 📊 Calculation for Progress Header
          final total = allTickets.length;
          final checkedIn = allTickets.where((doc) => doc['status'] == 'scanned').length;
          final progress = total > 0 ? checkedIn / total : 0.0;

          // 🔍 Filtering logic for local search
          final displayedTickets = allTickets.where((doc) {
            final email = (doc['userEmail'] as String).toLowerCase();
            return email.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // 📈 Dashboard Summary Header
              _buildSummaryHeader(total, checkedIn, progress),

              // 🔎 Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search attendee email...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 📜 Attendee List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: displayedTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = displayedTickets[index].data() as Map<String, dynamic>;
                    return _buildAttendeeCard(ticket);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ Dashboard-style Header
  Widget _buildSummaryHeader(int total, int checkedIn, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat("Total Guests", total.toString()),
              _buildHeaderStat("Checked In", checkedIn.toString()),
              _buildHeaderStat("Remaining", (total - checkedIn).toString()),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.indigo.shade300,
              color: Colors.greenAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(progress * 100).toInt()}% Attendance Complete",
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // ✅ Modern Attendee List Card
  Widget _buildAttendeeCard(Map<String, dynamic> ticket) {
    final bool isScanned = ticket['status'] == 'scanned';
    final DateTime bookedDate = (ticket['bookedAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat('MMM dd, hh:mm a').format(bookedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isScanned ? Colors.green.shade50 : Colors.indigo.shade50,
          child: Icon(
            isScanned ? Icons.verified_user : Icons.person_outline,
            color: isScanned ? Colors.green : Colors.indigo,
          ),
        ),
        title: Text(
          ticket['userEmail'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Booking: $formattedDate", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isScanned ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isScanned ? Colors.green.shade200 : Colors.orange.shade200),
          ),
          child: Text(
            isScanned ? "CHECKED-IN" : "PENDING",
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: isScanned ? Colors.green.shade700 : Colors.orange.shade700
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No attendees yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("Bookings will appear here in real-time.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}