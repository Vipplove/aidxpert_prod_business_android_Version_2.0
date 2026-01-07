import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/contact_us_controller.dart';

class ContactUsView extends GetView<ContactUsController> {
  const ContactUsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ContactUsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ContactUsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
