/// Tea Plantation Form Validators
/// Comprehensive validation system with clear error messages
class TeaValidators {
  TeaValidators._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIC VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a field is not empty
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be at most $maxLength characters';
    }
    return null;
  }

  /// Validates length range
  static String? lengthRange(
    String? value,
    int min,
    int max, [
    String? fieldName,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (value.length < min || value.length > max) {
      return '${fieldName ?? 'This field'} must be between $min and $max characters';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates username format
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 30) {
      return 'Username must be at most 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    if (value.startsWith('_') || value.endsWith('_')) {
      return 'Username cannot start or end with underscore';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates password confirmation matches
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates phone number
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces, dashes, and parentheses for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMERIC VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates numeric value
  static String? numeric(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validates integer value
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a whole number';
    }
    return null;
  }

  /// Validates numeric range
  static String? numericRange(
    String? value, {
    required double min,
    required double max,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    if (num < min || num > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }
    return null;
  }

  /// Validates minimum value
  static String? minValue(
    String? value,
    double min, [
    String? fieldName,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    if (num < min) {
      return '${fieldName ?? 'Value'} must be at least $min';
    }
    return null;
  }

  /// Validates maximum value
  static String? maxValue(
    String? value,
    double max, [
    String? fieldName,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    if (num > max) {
      return '${fieldName ?? 'Value'} must be at most $max';
    }
    return null;
  }

  /// Validates positive number
  static String? positive(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    if (num <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEA PLANTATION SPECIFIC VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates weight (kg)
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }
    if (weight > 10000) {
      return 'Weight seems too high. Please verify.';
    }
    return null;
  }

  /// Validates temperature (Celsius)
  static String? temperature(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature is required';
    }
    final temp = double.tryParse(value);
    if (temp == null) {
      return 'Please enter a valid temperature';
    }
    if (temp < -10 || temp > 50) {
      return 'Temperature must be between -10°C and 50°C';
    }
    return null;
  }

  /// Validates humidity (percentage)
  static String? humidity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Humidity is required';
    }
    final humidity = double.tryParse(value);
    if (humidity == null) {
      return 'Please enter a valid humidity';
    }
    if (humidity < 0 || humidity > 100) {
      return 'Humidity must be between 0% and 100%';
    }
    return null;
  }

  /// Validates pH value
  static String? pH(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'pH value is required';
    }
    final ph = double.tryParse(value);
    if (ph == null) {
      return 'Please enter a valid pH value';
    }
    if (ph < 0 || ph > 14) {
      return 'pH must be between 0 and 14';
    }
    return null;
  }

  /// Validates area (hectares)
  static String? area(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Area is required';
    }
    final area = double.tryParse(value);
    if (area == null) {
      return 'Please enter a valid area';
    }
    if (area <= 0) {
      return 'Area must be greater than 0';
    }
    if (area > 1000) {
      return 'Area seems too large. Please verify.';
    }
    return null;
  }

  /// Validates block/section name
  static String? blockName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Block name is required';
    }
    if (value.length < 2) {
      return 'Block name must be at least 2 characters';
    }
    if (value.length > 20) {
      return 'Block name must be at most 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\-_\s]+$').hasMatch(value)) {
      return 'Block name can only contain letters, numbers, spaces, hyphens, and underscores';
    }
    return null;
  }

  /// Validates batch ID
  static String? batchId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Batch ID is required';
    }
    if (!RegExp(r'^[A-Z]{2,3}-\d{4}-\d{4}$').hasMatch(value)) {
      return 'Batch ID must be in format: XX-YYYY-NNNN (e.g., TL-2024-0001)';
    }
    return null;
  }

  /// Validates GPS coordinates
  static String? latitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final lat = double.tryParse(value);
    if (lat == null) {
      return 'Please enter a valid latitude';
    }
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  static String? longitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final lon = double.tryParse(value);
    if (lon == null) {
      return 'Please enter a valid longitude';
    }
    if (lon < -180 || lon > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPOSITE VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Combines multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  /// Creates an optional validator that only runs if value is not empty
  static String? Function(String?) optional(
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return validator(value);
    };
  }

  /// Creates a conditional validator
  static String? Function(String?) when(
    bool condition,
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (!condition) {
        return null;
      }
      return validator(value);
    };
  }
}

/// Extension for easier validator chaining
extension ValidatorExtension on String? Function(String?) {
  /// Chain another validator
  String? Function(String?) and(String? Function(String?) other) {
    return (String? value) {
      final error = this(value);
      if (error != null) return error;
      return other(value);
    };
  }

  /// Make validator optional
  String? Function(String?) get optional {
    return TeaValidators.optional(this);
  }
}
