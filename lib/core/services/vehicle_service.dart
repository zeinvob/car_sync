import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for vehicle-related Firestore operations
class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new vehicle for a customer
  Future<String> addVehicle({
    required String customerId,
    required String brand,
    required String model,
    required String year,
    required String plateNumber,
    String? color,
    String? transmission,
    String? fuelType,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore.collection('vehicles').add({
        'customerId': customerId,
        'brand': brand,
        'model': model,
        'year': year,
        'plateNumber': plateNumber.toUpperCase(),
        'color': color ?? '',
        'transmission': transmission ?? '',
        'fuelType': fuelType ?? '',
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Vehicle added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('addVehicle error: $e');
      rethrow;
    }
  }

  /// Get all vehicles for a customer
  Future<List<Map<String, dynamic>>> getCustomerVehicles(String customerId) async {
    try {
      print('Fetching vehicles for customer: $customerId');
      
      final snapshot = await _firestore
          .collection('vehicles')
          .where('customerId', isEqualTo: customerId)
          .get();

      print('Found ${snapshot.docs.length} vehicles');

      final vehicles = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by createdAt descending
      vehicles.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return vehicles;
    } catch (e) {
      print('getCustomerVehicles error: $e');
      return [];
    }
  }

  /// Update a vehicle
  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Vehicle updated: $vehicleId');
    } catch (e) {
      print('updateVehicle error: $e');
      rethrow;
    }
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).delete();
      print('Vehicle deleted: $vehicleId');
    } catch (e) {
      print('deleteVehicle error: $e');
      rethrow;
    }
  }
}
