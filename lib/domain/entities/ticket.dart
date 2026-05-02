//ticket
class Ticket {
  final String ticketId;
  final String eventId;
  final String userId;
  final int seatNumber;
  final DateTime bookingDate;

  //NEW: Payment snapshot fields
  final String eventTitle;
  final double ticketPrice;
  final String currency;

  Ticket({
    required this.ticketId,
    required this.eventId,
    required this.userId,
    required this.seatNumber,
    required this.bookingDate,

    // NEW (safe defaults for old tickets)
    this.eventTitle = '',
    this.ticketPrice = 0.0,
    this.currency = 'LKR',
  });

  // -----------------------------
  // Firestore → Ticket
  // -----------------------------
  factory Ticket.fromMap(Map<String, dynamic> map, String id) {
    return Ticket(
      ticketId: id,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      seatNumber: map['seatNumber'] ?? 0,

      // Safe timestamp handling
      bookingDate: (map['bookedAt'] is Timestamp)
          ? (map['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),

      // 💰 NEW fields
      eventTitle: map['eventTitle'] ?? '',
      ticketPrice: (map['ticketPrice'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'LKR',
    );
  }

  // -----------------------------
  // Ticket → Firestore / SQLite
  // -----------------------------
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'userId': userId,
      'seatNumber': seatNumber,
      'bookedAt': bookingDate,

      // 💰 NEW fields
      'eventTitle': eventTitle,
      'ticketPrice': ticketPrice,
      'currency': currency,
    };
  }
}