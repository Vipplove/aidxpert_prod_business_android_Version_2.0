// controllers/sales_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../constants/app_constants.dart';
import '../../../../utils/helper.dart';

/// Unified User/Provider Model - Works with all 5 types
class UserModel {
  final int userId;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final String? profileImage;
  final String? city;
  final String? state;
  final Map<String, dynamic>? extraDetails;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    this.profileImage,
    this.city,
    this.state,
    this.extraDetails,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleData = json['role'] as Map<String, dynamic>?;

    // Detect which extra detail exists
    Map<String, dynamic>? extra;
    if (json['doctor_details'] != null) {
      extra = json['doctor_details'];
    } else if (json['lab_service_provider'] != null) {
      extra = json['lab_service_provider'];
    } else if (json['diagnostic_service_provider'] != null) {
      extra = json['diagnostic_service_provider'];
    } else if (json['ambulance_provider'] != null) {
      extra = json['ambulance_provider'];
    } else if (json['caretaker_provider'] != null) {
      extra = json['caretaker_provider'];
    }

    return UserModel(
      userId: json['user_id'] as int,
      fullName: "${json['first_name'] ?? ''} ${json['last_name'] ?? ''}".trim(),
      phone: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      role: roleData?['role_name'] ?? 'Unknown',
      profileImage: json['profile_image_name'],
      city: json['city'],
      state: json['state'],
      extraDetails: extra,
    );
  }
}

/// Main Controller - Handles Dashboard + Provider List
class SalesController extends GetxController {
  // Dashboard Summary
  final isLoading = true.obs;
  final dashboardData = <String, dynamic>{}.obs;

  // Provider List
  final isLoadingUsers = true.obs;
  final isLoadingMore = false.obs;
  final users = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final searchQuery = ''.obs;

  int currentPage = 1;
  int totalPages = 1;
  final int limit = 15;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary(); // Always load dashboard
  }

  /// Fetch Dashboard Summary (Total Users, Doctors, Labs, etc.)
  Future<void> fetchDashboardSummary() async {
    try {
      isLoading(true);
      final token = await readStr('token') ?? '';
      if (token.isEmpty) {
        customToast("Session expired", Colors.red);
        return;
      }

      final uri = Uri.parse(AppConstants.endpoint).replace(
        path: '/api/v1/operations/dashboard/sales/summary',
        queryParameters: {
          'period': 'datewise',
          'startDate': '2025-04-16',
          'endDate': '2025-12-16',
          'period': 'today',
        },
      );

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == true) {
          dashboardData.value = Map<String, dynamic>.from(res['data'] ?? {});
        }
      }
    } catch (e) {
      print("Dashboard error: $e");
    } finally {
      isLoading(false);
    }
  }

  /// Fetch Providers by Role (called from ProviderList with Get.arguments)
  Future<void> fetchUsersByRole(String role, {bool loadMore = false}) async {
    if (loadMore && currentPage > totalPages) return;

    if (!loadMore) {
      isLoadingUsers.value = true;
      currentPage = 1;
      users.clear();
      filteredUsers.clear();
    } else {
      isLoadingMore.value = true;
    }

    try {
      final token = await readStr('token') ?? '';
      if (token.isEmpty) return;

      final Map<String, String> params = {
        'page': currentPage.toString(),
        'limit': limit.toString(),
        'sortOrder': 'desc',
      };

      // Only add role if not "All"
      if (role != 'All' && role.isNotEmpty) {
        params['role'] = role;
      }

      if (searchQuery.value.trim().isNotEmpty) {
        params['searchQuery'] = searchQuery.value.trim();
      }

      final uri = Uri.parse(
              '${AppConstants.endpoint}/operations/dashboard/sales/all-users')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List items = json['users'] ?? [];
          final newUsers = items.map((e) => UserModel.fromJson(e)).toList();

          if (loadMore) {
            users.addAll(newUsers);
          } else {
            users.assignAll(newUsers);
          }

          filteredUsers.assignAll(users);
          totalPages = json['totalPages'] ?? 1;
          currentPage++;
        }
      }
    } catch (e) {
      customToast("Failed to load providers", Colors.red);
      print(e);
    } finally {
      isLoadingUsers.value = false;
      isLoadingMore.value = false;
      update(); // Important for GetBuilder
    }
  }

  /// Local instant search
  void onSearchChanged(String query) {
    searchQuery.value = query.trim();
    if (query.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      final q = query.toLowerCase();
      filteredUsers.assignAll(users.where((u) =>
          u.fullName.toLowerCase().contains(q) ||
          u.phone.contains(query) ||
          u.email.toLowerCase().contains(q)));
    }
    update();
  }

  /// Refresh provider list
  Future<void> refreshProviders(String role) async {
    await fetchUsersByRole(role);
  }
}
