// ignore_for_file: file_names
import 'package:get/get.dart';
import 'language/en_US.dart';
import 'language/hi_IN.dart';

class LocaleString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUs, 'hi_IN': hiIn};
}
