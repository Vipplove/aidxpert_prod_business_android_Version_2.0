// ignore_for_file: prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/helper.dart';
import '../../../routes/app_pages.dart';

class DiagnosticTestCard extends StatelessWidget {
  final data;

  const DiagnosticTestCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 0, bottom: 3),
                child: Text(
                  'Booking ID : #${data['id']}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.bloodtype, size: 40, color: Colors.red),
                title: Text(
                  getTestNames(jsonDecode(data['test_id'])) == ''
                      ? 'Prescription upload'
                      : getTestNames(jsonDecode(data['test_id'])),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Text(
                    'Patient : ' + getPatientDetails(data),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Date : ' + data['booking_date']),
                  Text(
                    'Paid : ₹${(double.tryParse(data['test_pay_amount'].toString()) ?? 0).ceil()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Time : ' + data['booking_time']),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['status'],
                    style: TextStyle(
                      color: getStatusColor(data['status']),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.lightGreen.shade300),
                    ),
                    onPressed: () {
                      Get.toNamed(
                        Routes.LABS_TEST_DETAILS,
                        arguments: data,
                      );
                    },
                    child: const Text(
                      'Book Details',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  getPatientDetails(data) {
    if (data['pt_name'] == null) {
      return data['patient_name'] +
          ' | ' +
          data['patient_mobile_no'].toString();
    } else {
      return data['pt_name'] + ' | ' + data['pt_mobile_no'].toString();
    }
  }
}
