import 'package:flutter/material.dart';
import 'package:get/get.dart';

var enrollAppHeader = Stack(
  children: [
    Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/image/bg-image.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Positioned(
      top: -30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Get.back();
            },
          ),
          const SizedBox(
            width: 10,
          ),
          Image.asset(
            'assets/logo/logo.png',
            height: 140,
            width: 140,
          ),
        ],
      ),
    ),
  ],
);
