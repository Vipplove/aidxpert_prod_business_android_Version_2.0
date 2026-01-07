class Validators {
  // 🔹 Email or Mobile field
  static String? validEmailMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email ID or Mobile Number is required';
    }
    return null;
  }

  // 🔹 Name validation
  static String? validName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    const namePattern = r'^[a-zA-Z][a-zA-Z\s]{2,49}$';
    final regExp = RegExp(namePattern);

    if (!regExp.hasMatch(value)) {
      return '$fieldName must be 3–50 characters and contain only letters and spaces';
    }

    final noSpaces = value.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'(.)\1{4,}').hasMatch(noSpaces)) {
      return '$fieldName contains repeated characters';
    }

    if (RegExp(r'(\w{2,})\1{2,}').hasMatch(noSpaces)) {
      return '$fieldName contains repetitive patterns';
    }

    return null;
  }

  // 🔹 Email validation
  static String? validEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email ID is required';
    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!pattern.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  // 🔹 Mobile number validation
  static String? validMobileno(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    const mobilePattern = r'^(\+91[\-\s]?)?[0]?[6-9]\d{9}$';
    if (!RegExp(mobilePattern).hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  // 🔹 Password validation
  static String? validPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // 🔹 Age validation
  static String? validAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 5) return 'Age must be greater than 5 years';
    return null;
  }

  // 🔹 Date validation
  static String? validDate(String? value) {
    if (value == null || value.isEmpty) return 'Date is required';
    return null;
  }

  // 🔹 Reason validation
  static String? validReason(String? value) {
    if (value == null || value.isEmpty) return 'Reason is required';
    return null;
  }

  // 🔹 Pincode validation
  static String? validPincode(String? value) {
    if (value == null || value.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Pincode must be 6 digits';
    }
    return null;
  }

  // 🔹 Required field
  static String? validRequired(String? value, String fieldName,
      {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (min != null && value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    if (max != null && value.length > max) {
      return '$fieldName must not exceed $max characters';
    }
    final noSpaces = value.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'(\w{3,})\1{2,}', caseSensitive: false).hasMatch(noSpaces)) {
      return '$fieldName contains invalid repetitive content.';
    }
    if (RegExp(r'(?:([a-z])\1{4,}|(abc|xyz){3,})', caseSensitive: false)
        .hasMatch(noSpaces)) {
      return '$fieldName contains spam-like content.';
    }
    return null;
  }

  // 🔹 Landline number validation
  static String? validLandlineNo(String? value) {
    if (value == null || value.isEmpty) return 'Landline number is required';
    const pattern =
        r'^(\+91[\-\s]?|0091[\-\s]?|0)?[1-9][0-9]{0,4}[\-\s]?[0-9]{6,8}$';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid Indian landline number';
    }
    return null;
  }

  // 🔹 Website URL validation
  static String? validWebsiteUrl(String? value) {
    if (value == null || value.isEmpty) return 'Website URL is required';
    const urlPattern =
        r'^(https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+(\.[a-zA-Z]{2,})(:[0-9]{2,5})?(\/.*)?$';
    if (!RegExp(urlPattern).hasMatch(value)) {
      return 'Please enter a valid website URL';
    }
    return null;
  }

  // 🔹 Price validation
  static String? validPrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Enter a valid price with up to 2 decimal places';
    }
    return null;
  }

  // 🔹 UPI ID validation
  static String? validUpiId(String? value) {
    if (value == null || value.isEmpty) return 'UPI ID is required';
    if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(value)) {
      return 'Enter a valid UPI ID (e.g., user@bank)';
    }
    return null;
  }

  // 🔹 Consultation fee validation
  static String? validConsultationFee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Consultation fee is required';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
      return 'Enter a valid consultation fee';
    }
    return null;
  }

  // 🔹 Radius / range validation
  static String? validRange(String? value) {
    if (value == null || value.isEmpty) return 'Radius is required';
    final range = int.tryParse(value);
    if (range == null || range < 5) return 'Radius must be greater than 5 Km';
    return null;
  }
}
