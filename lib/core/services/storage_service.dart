import 'package:car_sync/core/services/admin_service.dart';
import 'package:car_sync/core/services/booking_service.dart';
import 'package:car_sync/core/services/review_service.dart';
import 'package:car_sync/core/services/sparepart_service.dart';
import 'package:car_sync/core/services/user_service.dart';
import 'package:car_sync/core/services/vehicle_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:flutter/material.dart';

/// StorageService acts as a facade that delegates to individual services.
/// This maintains backward compatibility with existing code while
/// keeping the codebase organized into smaller, focused services.
/// 
/// Individual services:
/// - UserService: User profile and authentication data
/// - AdminService: Admin dashboard and foreman management
/// - BookingService: Booking CRUD operations
/// - VehicleService: Customer vehicle management
/// - WorkshopService: Workshop listing and details
/// - SparePartService: Spare parts inventory
/// - ReviewService: Workshop reviews and ratings
class StorageService {
  // Singleton instances of individual services
  final UserService _userService = UserService();
  final AdminService _adminService = AdminService();
  final BookingService _bookingService = BookingService();
  final VehicleService _vehicleService = VehicleService();
  final WorkshopService _workshopService = WorkshopService();
  final SparePartService _sparePartService = SparePartService();
  final ReviewService _reviewService = ReviewService();

  // ======================== USER METHODS ========================

  Future<bool> userExists(String uid) => _userService.userExists(uid);

  Future<void> saveGoogleUserData({
    required String uid,
    required String email,
    required String fullName,
  }) => _userService.saveGoogleUserData(uid: uid, email: email, fullName: fullName);

  Future<bool> needsProfileCompletion(String uid) => 
      _userService.needsProfileCompletion(uid);

  Future<void> completeUserProfile({
    required String uid,
    required String phone,
    required DateTime dateOfBirth,
  }) => _userService.completeUserProfile(uid: uid, phone: phone, dateOfBirth: dateOfBirth);

  Future<void> saveCustomerData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) => _userService.saveCustomerData(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
    emailVerified: emailVerified,
  );

  Future<String?> getUserRole(String uid) => _userService.getUserRole(uid);

  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) => _userService.saveUserData(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
    emailVerified: emailVerified,
  );

  Future<void> updateEmailVerified(String uid, bool verified) => 
      _userService.updateEmailVerified(uid, verified);

  Future<Map<String, dynamic>?> getUserData(String uid) => 
      _userService.getUserData(uid);

  Future<void> updateUserData({
    required String uid,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) => _userService.updateUserData(
    uid: uid,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
  );

  // ======================== ADMIN METHODS ========================

  Future<void> createForemanAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String createdBy,
    List<String> assignedSites = const [],
  }) => _adminService.createForemanAccount(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    createdBy: createdBy,
    assignedSites: assignedSites,
  );

  Future<List<Map<String, dynamic>>> getAllForemen() => 
      _adminService.getAllForemen();

  Future<void> updateForemanSites({
    required String uid,
    required List<String> assignedSites,
  }) => _adminService.updateForemanSites(uid: uid, assignedSites: assignedSites);

  Future<Map<String, dynamic>> getAdminDashboardData() => 
      _adminService.getAdminDashboardData();

  // ======================== BOOKING METHODS ========================

  Future<List<TimeOfDay>> getAvailableSlots({
    required String workshopId,
    required DateTime date,
  }) => _bookingService.getAvailableSlots(workshopId: workshopId, date: date);

  Future<String> createBooking({
    required String customerId,
    required String workshopId,
    required String serviceType,
    required DateTime bookingDate,
    String? notes,
    String? vehicleId,
  }) => _bookingService.createBooking(
    customerId: customerId,
    workshopId: workshopId,
    serviceType: serviceType,
    bookingDate: bookingDate,
    notes: notes,
    vehicleId: vehicleId,
  );

  Future<List<Map<String, dynamic>>> getCustomerBookings(String customerId) => 
      _bookingService.getCustomerBookings(customerId);

  Future<List<Map<String, dynamic>>> getBookingsByWorkshop(String workshopId) => 
      _bookingService.getBookingsByWorkshop(workshopId);

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) => _bookingService.updateBookingStatus(bookingId: bookingId, newStatus: newStatus);

  // ======================== VEHICLE METHODS ========================

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
  }) => _vehicleService.addVehicle(
    customerId: customerId,
    brand: brand,
    model: model,
    year: year,
    plateNumber: plateNumber,
    color: color,
    transmission: transmission,
    fuelType: fuelType,
    notes: notes,
  );

  Future<List<Map<String, dynamic>>> getCustomerVehicles(String customerId) => 
      _vehicleService.getCustomerVehicles(customerId);

  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> data,
  }) => _vehicleService.updateVehicle(vehicleId: vehicleId, data: data);

  Future<void> deleteVehicle(String vehicleId) => 
      _vehicleService.deleteVehicle(vehicleId);

  // ======================== WORKSHOP METHODS ========================

  Future<List<Map<String, dynamic>>> getWorkshopList({
    double? userLat,
    double? userLon,
  }) => _workshopService.getWorkshopList(userLat: userLat, userLon: userLon);

  // ======================== SPARE PART METHODS ========================

  Future<List<Map<String, dynamic>>> getAllSpareParts() => 
      _sparePartService.getAllSpareParts();

  Future<void> updateSparePartStock({
    required String docId,
    required int newStock,
  }) => _sparePartService.updateSparePartStock(docId: docId, newStock: newStock);

  Future<List<Map<String, dynamic>>> getRecentSpareParts() => 
      _sparePartService.getRecentSpareParts();

  // ======================== REVIEW METHODS ========================

  Future<List<Map<String, dynamic>>> getWorkshopReviews(String workshopId) =>
      _reviewService.getWorkshopReviews(workshopId);

  Future<void> addReview({
    required String workshopId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) => _reviewService.addReview(
    workshopId: workshopId,
    userId: userId,
    userName: userName,
    rating: rating,
    comment: comment,
  );

  Future<bool> canUserReview({
    required String workshopId,
    required String userId,
  }) => _reviewService.canUserReview(
    workshopId: workshopId,
    userId: userId,
  );

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) =>
      _reviewService.getUserReviews(userId);
}
