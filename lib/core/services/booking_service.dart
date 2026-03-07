import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for booking-related Firestore operations
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// All possible time slots (9am - 5pm)
  static const List<TimeOfDay> allTimeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
  ];

  /// Get available time slots for a workshop on a specific date
  Future<List<TimeOfDay>> getAvailableSlots({
    required String workshopId,
    required DateTime date,
  }) async {
    try {
      // Query all bookings for this workshop
      final snapshot = await _firestore
          .collection('bookings')
          .where('workshopId', isEqualTo: workshopId)
          .get();

      // Get booked hours for the selected date
      final bookedHours = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        
        // Skip cancelled bookings
        if (status == 'cancelled') continue;
        
        final bookingTimestamp = data['bookingDate'];
        if (bookingTimestamp == null) continue;
        
        final existingDate = (bookingTimestamp as Timestamp).toDate();
        
        // Check if same day
        if (existingDate.year == date.year &&
            existingDate.month == date.month &&
            existingDate.day == date.day) {
          bookedHours.add(existingDate.hour);
        }
      }

      // Filter out booked slots
      final availableSlots = allTimeSlots
          .where((slot) => !bookedHours.contains(slot.hour))
          .toList();

      print('Available slots for $workshopId on ${date.toString()}: ${availableSlots.length}');
      
      return availableSlots;
    } catch (e) {
      print('getAvailableSlots error: $e');
      // Return all slots if we can't check
      return List.from(allTimeSlots);
    }
  }

  /// Check if a time slot is already booked at a workshop
  Future<bool> isSlotAvailable({
    required String workshopId,
    required DateTime bookingDate,
  }) async {
    try {
      // Create a time window (same hour slot)
      final slotStart = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        bookingDate.hour,
        0,
      );
      final slotEnd = slotStart.add(const Duration(hours: 1));

      // Query all bookings for this workshop (avoid compound index requirement)
      final snapshot = await _firestore
          .collection('bookings')
          .where('workshopId', isEqualTo: workshopId)
          .get();

      // Filter locally for the time slot and active status
      final conflictingBookings = snapshot.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        
        // Skip cancelled bookings
        if (status == 'cancelled') return false;
        
        // Check if booking is in the same time slot
        final bookingTimestamp = data['bookingDate'];
        if (bookingTimestamp == null) return false;
        
        final existingDate = (bookingTimestamp as Timestamp).toDate();
        return existingDate.isAfter(slotStart.subtract(const Duration(seconds: 1))) &&
               existingDate.isBefore(slotEnd);
      }).toList();

      print('Slot check: workshopId=$workshopId, slot=${slotStart.toString()}, conflicts=${conflictingBookings.length}');
      
      return conflictingBookings.isEmpty;
    } catch (e) {
      print('isSlotAvailable error: $e');
      // If we can't check, block the booking to be safe
      throw Exception('Unable to verify slot availability. Please try again.');
    }
  }

  /// Creates a new booking in Firestore
  Future<String> createBooking({
    required String customerId,
    required String workshopId,
    required String serviceType,
    required DateTime bookingDate,
    String? notes,
    String? vehicleId,
  }) async {
    try {
      // Check if slot is available before booking
      final isAvailable = await isSlotAvailable(
        workshopId: workshopId,
        bookingDate: bookingDate,
      );

      if (!isAvailable) {
        throw Exception('slot-not-available');
      }

      final docRef = await _firestore.collection('bookings').add({
        'customerId': customerId,
        'workshopId': workshopId,
        'serviceType': serviceType,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'notes': notes ?? '',
        'vehicleId': vehicleId ?? '',
        'status': 'requested',
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
        final vehicleId = (data['vehicleId'] ?? '').toString();
        
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

        // Get vehicle details
        Map<String, dynamic> vehicleData = {};
        if (vehicleId.isNotEmpty) {
          try {
            final vehicleDoc = await _firestore.collection('vehicles').doc(vehicleId).get();
            if (vehicleDoc.exists) {
              vehicleData = vehicleDoc.data() ?? {};
            }
          } catch (e) {
            print('Error loading vehicle for booking ${doc.id}: $e');
          }
        }

        // Format vehicle display name
        String vehicleDisplay = '';
        if (vehicleData.isNotEmpty) {
          final brand = vehicleData['brand'] ?? '';
          final model = vehicleData['model'] ?? '';
          final plateNo = vehicleData['plateNumber'] ?? vehicleData['plateNo'] ?? '';
          vehicleDisplay = '$brand $model • $plateNo';
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
          'vehicleId': vehicleId,
          'vehicleDisplay': vehicleDisplay,
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
          'bookingDate': data['bookingDate'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      // Hide completed / cancelled - only active bookings
      final filtered = bookingsWithCustomer.where((booking) {
        final status = (booking['status'] ?? '').toString().toLowerCase();
        return status != 'completed' && status != 'cancelled';
      }).toList();

      // Sort by booking date
      filtered.sort((a, b) {
        final aTime = a['bookingDate'];
        final bTime = b['bookingDate'];

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

  /// Stream of active bookings count (for admin notifications)
  Stream<int> getActiveBookingsCountStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();

        if (status != 'completed' && status != 'cancelled') {
          count++;
        }
      }

      return count;
    });
  }
}
