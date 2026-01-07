// screens/caretaker/caretaker_staff.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../constants/app_constants.dart';
import '../../../../../utils/helper.dart';
import '../../../../routes/app_pages.dart';
import '../../component/caretaker_bottom_navbar.dart';
import '../controllers/caretaker_controller.dart';

class CareTakerStaff extends StatelessWidget {
  const CareTakerStaff({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CaretakerController>();
    controller.fetchCaretakerStaff();

    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed(Routes.CARETAKER_PROVIDER_DASHBOARD);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppConstants.appPrimaryColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'My Caretakers',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 28),
              onPressed: () {
                Get.toNamed(Routes.CARETAKER_ADD_STAFF);
              },
            ),
          ],
        ),
        bottomNavigationBar: const CaretakerProviderBottomNavBar(index: 2),
        body: Obx(() {
          if (controller.isLoading.value) {
            return  Center(child: loading);
          }

          return RefreshIndicator(
            onRefresh: controller.fetchCaretakerStaff,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.caretakerStaff.length,
              itemBuilder: (context, index) {
                final staff = controller.caretakerStaff[index];
                final user = staff['user'] as Map<String, dynamic>;
                final caretakerTypes =
                    List<String>.from(staff['caretaker_type'] ?? []);

                String name =
                    "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
                        .trim();
                if (name.isEmpty) name = "Caretaker #${staff['caretaker_id']}";

                String photoUrl = user['profile_image_name'] ?? '';
                String phone = user['phone_number'] ?? '';
                String location = staff['location'] ?? 'Not specified';
                String description =
                    staff['description'] ?? 'No description available';
                String currentStatus =
                    (staff['current_status'] ?? 'Available').toString();
                double rating = (staff['rating'] ?? 0).toDouble();
                int ratingCount = staff['rating_count'] ?? 0;

                List<String> documents =
                    List<String>.from(staff['upload_documents'] ?? []);

                Color statusColor = currentStatus.toLowerCase() == 'available'
                    ? Colors.green
                    : Colors.orange;
                Color statusBgColor = currentStatus.toLowerCase() == 'available'
                    ? Colors.green.shade50
                    : Colors.orange.shade50;

                return staff.length > 0
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: InkWell(
                          onTap: () async {
                            Get.toNamed(Routes.CARETAKER_ADD_STAFF,
                                arguments: staff);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        photoUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.person,
                                              size: 40, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(location,
                                                  style: TextStyle(
                                                      color: Colors
                                                          .grey.shade700)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                                color: statusBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text(currentStatus,
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.phone,
                                            color: Colors.green, size: 28),
                                        onPressed: () async {
                                          final Uri uri =
                                              Uri(scheme: 'tel', path: phone);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          } else {
                                            customToast(
                                                "Cannot make call", Colors.red);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (caretakerTypes.isNotEmpty) ...[
                                  const Text("Specializations",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: caretakerTypes
                                        .map((type) => Chip(
                                              label: Text(type,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(description,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        height: 1.4)),
                                if (rating > 0) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Text(rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      Text(" ($ratingCount reviews)",
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                                if (documents.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text("Verification Documents",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    children: documents
                                        .map((docUrl) => GestureDetector(
                                              onTap: () async {
                                                final Uri uri =
                                                    Uri.parse(docUrl);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                } else {
                                                  customToast(
                                                      "Cannot open document",
                                                      Colors.red);
                                                }
                                              },
                                              child: Chip(
                                                avatar: const Icon(
                                                    Icons.picture_as_pdf,
                                                    size: 18,
                                                    color: Colors.red),
                                                label: Text(
                                                    "Document ${documents.indexOf(docUrl) + 1}",
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                                backgroundColor:
                                                    Colors.red.shade50,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text('No caretakers added yet',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
              },
            ),
          );
        }),
      ),
    );
  }
}
