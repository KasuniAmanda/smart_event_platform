import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. LOGIC PROVIDER
final organizerLogicProvider = Provider((ref) => OrganizerLogic());

// 2. REACTIVE EVENTS STREAM
final organizerEventsStreamProvider =
    StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('events')
      .where('organizerId', isEqualTo: user.uid)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});