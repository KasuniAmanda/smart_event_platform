class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int totalSeats;
  final int availableSeats;
  final String organizerId;
  final bool isFeatured; // ✅ Add this

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.totalSeats,
    required this.availableSeats,
    required this.organizerId,
    this.isFeatured = false, // ✅ Default to false
  });
}