import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for booking-related Firestore operations
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new booking in Firestore
  Future<String> createBooking({
    required String customerId,
    required String workshopId,
    required String serviceType,
    required DateTime bookingDate,
    required String timeSlot,
    String? notes,
    String? vehicleId,
  }) async {
    try {
      final docRef = await _firestore.collection('bookings').add({
        'customerId': customerId,
        'workshopId': workshopId,
        'serviceType': serviceType,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'slotTime': Timestamp.fromDate(bookingDate),
        'timeSlot': timeSlot,
        'notes': notes ?? '',
        'vehicleId': vehicleId ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Booking created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('createBooking error: $e');
      rethrow;
    }
  }

  /// Gets all bookings for a customer
  Future<List<Map<String, dynamic>>> getCustomerBookings(String customerId) async {
    try {
      print('Fetching bookings for customer: $customerId');
      
      final snapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .get();

      print('Found ${snapshot.docs.length} bookings');

      final List<Map<String, dynamic>> bookings = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Booking data: $data');
        final workshopId = (data['workshopId'] ?? '').toString();
        
        // Get workshop details
        Map<String, dynamic> workshopData = {};
        if (workshopId.isNotEmpty) {
          try {
            final workshopDoc = await _firestore.collection('workshops').doc(workshopId).get();
            if (workshopDoc.exists) {
              workshopData = workshopDoc.data() ?? {};
            }
          } catch (e) {
            print('Error loading workshop for booking ${doc.id}: $e');
          }
        }

        bookings.add({
          'id': doc.id,
          'customerId': data['customerId'] ?? '',
          'workshopId': workshopId,
          'workshopName': workshopData['name'] ?? 'Unknown Workshop',
          'workshopAddress': workshopData['address'] ?? '',
          'serviceType': data['serviceType'] ?? '',
          'status': data['status'] ?? 'pending',
          'bookingDate': data['bookingDate'],
          'slotTime': data['slotTime'],
          'timeSlot': data['timeSlot'] ?? '',
          'notes': data['notes'] ?? '',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      // Sort locally by createdAt descending
      bookings.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return bookings;
    } catch (e) {
      print('getCustomerBookings error: $e');
      return [];
    }
  }

  /// Get bookings by workshop
  Future<List<Map<String, dynamic>>> getBookingsByWorkshop(String workshopId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('workshopId', isEqualTo: workshopId)
          .get();

      final List<Map<String, dynamic>> bookingsWithCustomer = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final customerId = (data['customerId'] ?? '').toString();
        Map<String, dynamic> customerData = {};

        if (customerId.isNotEmpty) {
          try {
            final userDoc = await _firestore.collection('users').doc(customerId).get();
            if (userDoc.exists) {
              customerData = userDoc.data() ?? {};
            }
          } catch (e) {
            print('Error loading user for booking ${doc.id}: $e');
          }
        }

        bookingsWithCustomer.add({
          'id': doc.id,
          'customerId': customerId,
          'customerName': customerData['name'] ??
              customerData['fullName'] ??
              customerData['username'] ??
              'Unknown Customer',
          'customerPhone': customerData['phone'] ??
              customerData['contact'] ??
              customerData['phoneNumber'] ??
              'No contact',
          'customerEmail': customerData['email'] ?? 'No email',
          'serviceType': data['serviceType'] ?? '',
          'status': data['status'] ?? '',
          'workshopId': data['workshopId'] ?? '',
          'slotTime': data['slotTime'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      // Hide completed / cancelled - only active bookings
      final filtered = bookingsWithCustomer.where((booking) {
        final status = (booking['status'] ?? '').toString().toLowerCase();
        return status != 'completed' && status != 'cancelled';
      }).toList();

      // Sort by slot time
      filtered.sort((a, b) {
        final aTime = a['slotTime'];
        final bTime = b['slotTime'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return aTime.toDate().compareTo(bTime.toDate());
        }
        return 0;
      });

      return filtered;
    } catch (e) {
      print('getBookingsByWorkshop error: $e');
      return [];
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('updateBookingStatus error: $e');
    }
  }
}
