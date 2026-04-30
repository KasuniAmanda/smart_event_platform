class Ticket {
  final String ticketId;
  final String eventId;
  final String userId;
  final int seatNumber;
  final DateTime bookingDate;

  Ticket({
    required this.ticketId,
    required this.eventId,
    required this.userId,
    required this.seatNumber,
    required this.bookingDate,
  });
}