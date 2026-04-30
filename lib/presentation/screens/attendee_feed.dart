import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import '../providers/event_provider.dart';
import '../../data/datasources/booking_service.dart';
import '../../data/datasources/local_database.dart'; 
import '../../data/datasources/weather_service.dart'; // MEMBER 4: API Import
import '../../domain/entities/event.dart';
import 'my_tickets_screen.dart';
import 'profile_screen.dart'; 

class AttendeeFeed extends ConsumerWidget {
  const AttendeeFeed({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _handleBooking(BuildContext context, Event event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing your booking...'), duration: Duration(seconds: 1)),
    );

    try {
      await BookingService().bookTicket(
        eventId: event.id,
        userId: user.uid,
        userEmail: user.email ?? 'No Email',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! You are going to ${event.title} 🎫'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final featuredAsync = ref.watch(featuredEventsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Discover Events', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: 'My Tickets',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTicketsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Featured Highlights
          featuredAsync.when(
            data: (featuredEvents) {
              if (featuredEvents.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text("Featured Highlights ✨", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                  ),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: featuredEvents.length,
                      itemBuilder: (context, index) => _buildFeaturedCard(context, featuredEvents[index]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(color: Colors.indigo),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
              decoration: const InputDecoration(
                hintText: 'Search by event name...',
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text("Upcoming Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // 3. Dynamic List
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) return _buildEmptyState(ref);

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isFull = event.availableSeats <= 0;
                    String formattedDate = DateFormat('EEE, MMM dd').format(event.date);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📅 $formattedDate\n📍 ${event.location}", 
                              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                            const SizedBox(height: 6),
                            
                            // MEMBER 4: Weather API Implementation
                            FutureBuilder<String>(
                              future: WeatherService().getWeather(event.location),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text("Checking weather...", style: TextStyle(fontSize: 10, color: Colors.blueGrey));
                                }
                                return Row(
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text("Weather: ${snapshot.data ?? 'N/A'}", 
                                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        
                        trailing: SizedBox(
                          width: 140, 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // MEMBER 3: SQLite Favorite (UI Placeholder)
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.bookmark_border, color: Colors.indigo, size: 22),
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    try {
                                      await LocalDatabase.instance.cacheEvent(event);
                                      await LocalDatabase.instance.addToFavorites(event.id, user.uid);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Saved to SQLite! 💾'))
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint("SQLite Error: $e");
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // Booking Button
                              Flexible(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFull ? Colors.grey : Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isFull ? null : () => _handleBooking(context, event),
                                  child: Text(isFull ? 'Full' : 'Book', style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Event event) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FEATURED", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              event.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(event.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No events found', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}