import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/about_us_controller.dart';

class AboutUsView extends GetView<AboutUsController> {
  const AboutUsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AboutUsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'AboutUsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
