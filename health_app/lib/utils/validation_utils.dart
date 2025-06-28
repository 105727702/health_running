class ValidationUtils {
  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    // Check for valid characters (letters, numbers, underscore)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }
    return null;
  }

  // Password strength validation (for sign up)
  static String? validatePasswordStrength(String? value) {
    String? basicValidation = validatePassword(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    if (value != null) {
      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
      bool hasLowercase = value.contains(RegExp(r'[a-z]'));
      bool hasDigits = value.contains(RegExp(r'[0-9]'));

      if (!hasUppercase || !hasLowercase || !hasDigits) {
        return 'Password must contain uppercase, lowercase, and numbers';
      }
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Basic email regex pattern
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    if (value.length > 50) {
      return 'Email must be less than 50 characters';
    }

    return null;
  }

  // Username or Email validation (for login)
  static String? validateUsernameOrEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username or email';
    }

    if (value.length < 3) {
      return 'Username or email must be at least 3 characters';
    }

    if (value.length > 50) {
      return 'Username or email must be less than 50 characters';
    }

    // Check if it's an email format
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp emailRegExp = RegExp(emailPattern);

    // Check if it's a username format
    String usernamePattern = r'^[a-zA-Z0-9_]+$';
    RegExp usernameRegExp = RegExp(usernamePattern);

    // Must be either a valid email or valid username
    if (!emailRegExp.hasMatch(value) && !usernameRegExp.hasMatch(value)) {
      return 'Enter a valid username or email address';
    }

    return null;
  }

  // General form validation
  static bool isFormValid(List<String?> validationResults) {
    return validationResults.every((result) => result == null);
  }
}
