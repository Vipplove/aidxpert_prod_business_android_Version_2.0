// ignore_for_file: depend_on_referenced_packages, deprecated_member_use
import 'dart:async';

import 'package:get/get.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter/material.dart';
import '../../../../utils/helper.dart';
import '../../../../constants/app_constants.dart';

class LocationController extends GetxController {
  RxString address = 'Pune'.obs;
  RxString city = ''.obs;
  RxString state = ''.obs;
  RxString latitude = ''.obs;
  RxString longitude = ''.obs;
  RxList<dynamic> predictionList = [].obs;
  RxBool loading = false.obs;
  late GooglePlace googlePlace;
  Timer? _debounce;

  @override
  Future<void> onInit() async {
    super.onInit();
    googlePlace = GooglePlace(AppConstants.googleApiKey);
    loading.value = false;
    address.value = await readStr('location') ?? 'Pune';
    city.value = await readStr('city') ?? '';
    state.value = await readStr('state') ?? '';
    latitude.value = await readStr('latitude') ?? '';
    longitude.value = await readStr('longitude') ?? '';
    update(['address-field']);
  }

  updateLocation({
    required String address,
    required String city,
    required String state,
    required String latitude,
    required String longitude,
  }) async {
    this.address.value = address;
    this.city.value = city;
    this.state.value = state;
    this.latitude.value = latitude;
    this.longitude.value = longitude;
    await saveStr('location', address);
    await saveStr('city', city);
    await saveStr('state', state);
    await saveStr('latitude', latitude);
    await saveStr('longitude', longitude);
    update(['address-field']);
  }

  searchLocation(String text) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (text.length > 2) {
        loading.value = true;
        update(['location-search']);
        try {
          var result = await googlePlace.autocomplete.get(
            text,
            components: [Component("country", "in")],
          );
          if (result != null && result.predictions != null) {
            predictionList.value = result.predictions!.map((prediction) {
              return {
                'place_id': prediction.placeId,
                'description': prediction.description,
                'structured_formatting': prediction.structuredFormatting != null
                    ? {
                        'main_text': prediction.structuredFormatting!.mainText,
                        'secondary_text':
                            prediction.structuredFormatting!.secondaryText,
                      }
                    : null,
              };
            }).toList();
          } else {
            predictionList.value = [];
          }
        } catch (e) {
          predictionList.value = [];
          customToast('Failed to search location: $e', Colors.red);
        } finally {
          loading.value = false;
          update(['location-search']);
        }
      } else {
        resetLocationList();
      }
    });
  }

  getPlaceDetails(String placeId, {required String description}) async {
    try {
      var result = await googlePlace.details.get(placeId);
      if (result != null && result.result != null) {
        var location = result.result!.geometry!.location!;
        var addressComponents = result.result!.addressComponents!;
        String city = '';
        String state = '';
        for (var component in addressComponents) {
          if (component.types!.contains('locality')) {
            city = component.longName!;
          }
          if (component.types!.contains('administrative_area_level_1')) {
            state = component.longName!;
          }
        }
        updateLocation(
          address: description,
          city: city,
          state: state,
          latitude: location.lat.toString(),
          longitude: location.lng.toString(),
        );
        predictionList.clear();
        update(['location-search', 'address-field']);
        Get.back(result: {
          'address': description,
          'city': city,
          'state': state,
          'latitude': location.lat.toString(),
          'longitude': location.lng.toString(),
        });
      } else {
        throw Exception('No details available for this place');
      }
    } catch (e) {
      customToast('Failed to get place details: $e', Colors.red);
    }
  }

  resetLocationList() {
    loading.value = false;
    predictionList.value = [];
    update(['location-search']);
  }
}
