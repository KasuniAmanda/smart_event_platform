//Event 
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int totalSeats;
  final int availableSeats;
  final String organizerId;
  final bool isFeatured;

  //NEW (PAYMENT FIELDS)
  final double ticketPrice;
  final bool isPaidEvent;
  final String currency;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.totalSeats,
    required this.availableSeats,
    required this.organizerId,
    this.isFeatured = false,

    // NEW
    this.ticketPrice = 0.0,
    this.isPaidEvent = false,
    this.currency = "LKR",
  });

  // -----------------------------
  // Firestore → Event mapping
  // -----------------------------
  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      location: map['location'] ?? '',
      totalSeats: map['totalSeats'] ?? 0,
      availableSeats: map['availableSeats'] ?? 0,
      organizerId: map['organizerId'] ?? '',
      isFeatured: map['isFeatured'] ?? false,

      // 🔥 NEW
      ticketPrice: (map['ticketPrice'] ?? 0).toDouble(),
      isPaidEvent: map['isPaidEvent'] ?? false,
      currency: map['currency'] ?? "LKR",
    );
  }

  // -----------------------------
  // Event → Firestore mapping
  // -----------------------------
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'organizerId': organizerId,
      'isFeatured': isFeatured,

      // 🔥 NEW
      'ticketPrice': ticketPrice,
      'isPaidEvent': isPaidEvent,
      'currency': currency,
    };
  }
}