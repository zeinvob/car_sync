import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("Error checking user existence: $e");
      return false;
    }
  }

  // Save Google user data (minimal data - no phone/dob)
Future<void> saveGoogleUserData({
  required String uid,
  required String email,
  required String fullName,
}) async {
  try {
    final docRef = _usersCollection.doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'role': 'customer',
        'emailVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    print("Google user data saved/updated for UID: $uid");
  } catch (e) {
    print("Error saving Google user data: $e");
    rethrow;
  }
}

  // Check if Google user has complete profile (has phone and dateOfBirth)
  Future<bool> needsProfileCompletion(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if phone and dateOfBirth fields exist
        bool hasPhone =
            data.containsKey('phone') &&
            data['phone'] != null &&
            data['phone'].toString().isNotEmpty;
        bool hasDob =
            data.containsKey('dateOfBirth') && data['dateOfBirth'] != null;

        // If either is missing, profile needs completion
        return !hasPhone || !hasDob;
      }
      return true; // If no document, needs completion
    } catch (e) {
      print("Error checking profile completion: $e");
      return true;
    }
  }

  // Complete profile with phone and date of birth
  Future<void> completeUserProfile({
    required String uid,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User profile completed for UID: $uid");
    } catch (e) {
      print("Error completing user profile: $e");
      throw e;
    }
  }

  // Save customer data (for self-registration)
  Future<void> saveCustomerData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'role': 'customer',
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Customer data saved for UID: $uid");
    } catch (e) {
      print("Error saving customer data: $e");
      throw e;
    }
  }

  // Create foreman account (admin only)
  Future<void> createForemanAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String createdBy,
    List<String> assignedSites = const [],
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': 'foreman',
        'createdBy': createdBy,
        'assignedSites': assignedSites,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman account created for UID: $uid");
    } catch (e) {
      print("Error creating foreman: $e");
      throw e;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  // Get all foremen (admin only)
  Future<List<Map<String, dynamic>>> getAllForemen() async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('role', isEqualTo: 'foreman')
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error getting foremen: $e");
      return [];
    }
  }

  // Update foreman assigned sites
  Future<void> updateForemanSites({
    required String uid,
    required List<String> assignedSites,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'assignedSites': assignedSites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman sites updated for UID: $uid");
    } catch (e) {
      print("Error updating foreman sites: $e");
      throw e;
    }
  }

  // Save user data (your existing method - keep for backward compatibility)
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'role': 'customer',
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User data saved for UID: $uid");
    } catch (e) {
      print("Error saving user data: $e");
      throw e;
    }
  }

  // Update email verification status
  Future<void> updateEmailVerified(String uid, bool verified) async {
    try {
      await _usersCollection.doc(uid).update({
        'emailVerified': verified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Email verification status updated for UID: $uid");
    } catch (e) {
      print("Error updating email verification: $e");
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData({
    required String uid,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      await _usersCollection.doc(uid).update(updates);
      print("User data updated for UID: $uid");
    } catch (e) {
      print("Error updating user data: $e");
      throw e;
    }
  }

  //--------------------------- Admin Functions ---------------------------
  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // 1) Today's bookings (change field name if yours is different)
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'bookingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      // 2) Services
      final servicesSnapshot = await _firestore.collection('services').get();

      // 3) Towing
      final towingSnapshot = await _firestore
          .collection('towing_requests')
          .where('status', isEqualTo: 'active')
          .get();

      // 4) Spareparts low stock (YOUR inventory)
      final lowStockSnapshot = await _firestore
          .collection('spareparts')
          .where('stock', isLessThanOrEqualTo: 5)
          .get();

      // 5) Revenue from invoices
      final invoicesSnapshot = await _firestore
          .collection('invoices')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // 6) Recent activities
      final activitySnapshot = await _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final bookings = bookingsSnapshot.docs.map((d) => d.data()).toList();
      final services = servicesSnapshot.docs.map((d) => d.data()).toList();

      // Cars In Service
      final carsInService = services.where((s) {
        final status = (s['status'] ?? '').toString();
        return status == 'Diagnosing' ||
            status == 'Diagnosis' ||
            status == 'Repairing' ||
            status == 'In Progress';
      }).length;

      // Completed
      final completedServices = services.where((s) {
        final status = (s['status'] ?? '').toString();
        return status == 'Completed';
      }).length;

      // Revenue sum
      double todayRevenue = 0;
      for (final doc in invoicesSnapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is int) todayRevenue += amount.toDouble();
        if (amount is double) todayRevenue += amount;
      }

      // Appointments list
      final appointments = bookings.map((b) {
        final date = (b['bookingDate'] is Timestamp)
            ? (b['bookingDate'] as Timestamp).toDate()
            : null;

        return {
          'time': date != null ? DateFormat('hh:mm a').format(date) : '--:--',
          'customerName': b['customerName'] ?? 'Unknown',
          'carPlate': b['carPlate'] ?? '-',
          'serviceType': b['serviceType'] ?? '-',
          'status': b['status'] ?? '-',
        };
      }).toList();

      // Status overview
      final statusOverview = {
        'Booked': services.where((s) => (s['status'] ?? '') == 'Booked').length,
        'Diagnosing': services
            .where((s) => (s['status'] ?? '') == 'Diagnosing')
            .length,
        'Repairing': services
            .where((s) => (s['status'] ?? '') == 'Repairing')
            .length,
        'Ready for Pickup': services
            .where((s) => (s['status'] ?? '') == 'Ready for Pickup')
            .length,
      };

      // Alerts
      final alerts = <String>[];

      for (final doc in lowStockSnapshot.docs) {
        final item = doc.data();
        alerts.add("Low stock: ${item['part'] ?? 'Unknown Part'}");
      }

      for (final b in bookings) {
        final foremanId = (b['foremanId'] ?? '').toString();
        final status = (b['status'] ?? '').toString();
        final paymentStatus = (b['paymentStatus'] ?? '').toString();
        final carPlate = (b['carPlate'] ?? 'vehicle').toString();

        if (foremanId.isEmpty) alerts.add("Unassigned job: $carPlate");
        if (status == 'Ready for Pickup') {
          alerts.add("Customer waiting for pickup: $carPlate");
        }
        if (paymentStatus == 'Pending')
          alerts.add("Pending payment: $carPlate");
      }

      final recentActivities = activitySnapshot.docs
          .map((d) => (d.data()['message'] ?? '').toString())
          .where((m) => m.isNotEmpty)
          .toList();

      return {
        'todayBookings': bookings.length,
        'carsInService': carsInService,
        'completedServices': completedServices,
        'activeTowingRequests': towingSnapshot.docs.length,
        'todayRevenue': todayRevenue,
        'lowStockItems': lowStockSnapshot.docs.length,
        'appointments': appointments,
        'statusOverview': statusOverview,
        'alerts': alerts,
        'recentActivities': recentActivities,
      };
    } catch (e) {
      print("getAdminDashboardData error: $e");
      return {
        'todayBookings': 0,
        'carsInService': 0,
        'completedServices': 0,
        'activeTowingRequests': 0,
        'todayRevenue': 0.0,
        'lowStockItems': 0,
        'appointments': <Map<String, dynamic>>[],
        'statusOverview': <String, int>{},
        'alerts': <String>[],
        'recentActivities': <String>[],
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAllSpareParts() async {
    try {
      final snapshot = await _firestore.collection('spareparts').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'part': data['part'] ?? '',
          'car_model': data['car_model'] ?? '',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0,
          'stock': data['stock'] ?? 0,
          'type': data['type'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("getAllSpareParts error: $e");
      return [];
    }
  }

  Future<void> updateSparePartStock({
    required String docId,
    required int newStock,
  }) async {
    try {
      await _firestore.collection('spareparts').doc(docId).update({
        'stock': newStock,
      });
    } catch (e) {
      print("updateSparePartStock error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSpareParts() async {
    try {
      final snapshot = await _firestore
          .collection('spareparts')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'part': data['part'] ?? '',
          'car_model': data['car_model'] ?? '',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0,
          'stock': data['stock'] ?? 0,
          'type': data['type'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('getRecentSpareParts error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorkshopList() async {
    try {
      final workshopSnapshot = await _firestore.collection('workshops').get();
      final bookingSnapshot = await _firestore.collection('bookings').get();

      final bookings = bookingSnapshot.docs.map((doc) => doc.data()).toList();

      return workshopSnapshot.docs.map((doc) {
        final data = doc.data();
        final workshopId = doc.id;

        final activeBookingCount = bookings.where((booking) {
          final sameWorkshop = booking['workshopId'] == workshopId;
          final status = (booking['status'] ?? '').toString().toLowerCase();

          return sameWorkshop && status != 'completed' && status != 'cancelled';
        }).length;

        final completedBookingCount = bookings.where((booking) {
          final sameWorkshop = booking['workshopId'] == workshopId;
          final status = (booking['status'] ?? '').toString().toLowerCase();

          return sameWorkshop && status == 'completed';
        }).length;

        return {
          'id': workshopId,
          'name': data['name'] ?? 'Workshop',
          'address': data['address'] ?? 'No address',
          'rating': data['rating'] ?? 0,
          'isActive': data['isActive'] ?? false,
          'bookingCount': activeBookingCount,
          'completedCount': completedBookingCount,
        };
      }).toList();
    } catch (e) {
      print('getWorkshopList error: $e');
      return [];
    }
  }

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

    // Hide completed / cancelled if you want only active bookings
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
      
      // Simple query without orderBy to avoid index requirement
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
}
