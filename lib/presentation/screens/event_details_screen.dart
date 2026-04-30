import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event.dart';
import '../../data/datasources/booking_service.dart';
import '../../core/services/notification_service.dart';

// ✅ Provider for the Booking Service
final bookingProvider = Provider((ref) => BookingService());

class EventDetailsScreen extends ConsumerStatefulWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _isBooking = false;

  Future<void> _handleBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isBooking = true);

    try {
      // 1. Call the Booking Service
      await ref.read(bookingProvider).bookTicket(
            eventId: widget.event.id,
            userId: user.uid,
            userEmail: user.email ?? 'Guest',
          );

      // 2. Schedule Local Notification Reminder
      await NotificationService().scheduleEventReminder(
        widget.event.id.hashCode,
        widget.event.title,
        widget.event.date,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success! Ticket booked 🎫"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(widget.event.date);
    final String formattedTime = DateFormat('hh:mm a').format(widget.event.date);
    final bool isFull = widget.event.availableSeats <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Event Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎭 Hero Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(widget.event.location, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 📊 Capacity Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFull ? Icons.block : Icons.event_seat,
                            color: isFull ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isFull ? "Event is Sold Out" : "${widget.event.availableSeats} Seats still available",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red.shade900 : Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 📝 Info Tiles
                  _buildDetailTile(Icons.calendar_month, "Date", formattedDate),
                  _buildDetailTile(Icons.access_time, "Time", formattedTime),
                  const Divider(indent: 20, endIndent: 20, height: 40),

                  // 📖 Description
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "About the Event",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.event.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 🎫 Floating Booking Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: _isBooking
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.grey : Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: isFull ? null : _handleBooking,
                    child: Text(
                      isFull ? "FULLY BOOKED" : "RESERVE MY SPOT",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade50,
        child: Icon(icon, color: Colors.indigo, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
    );
  }
}