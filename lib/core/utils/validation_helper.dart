class ValidationHelper {
  ValidationHelper._();

  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Phone number validation (basic)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone.trim());
  }

  // Amount validation
  static bool isValidAmount(String amount) {
    if (amount.trim().isEmpty) return false;
    final parsed = double.tryParse(amount.trim());
    return parsed != null && parsed >= 0;
  }

  // Positive amount validation
  static bool isValidPositiveAmount(String amount) {
    if (amount.trim().isEmpty) return false;
    final parsed = double.tryParse(amount.trim());
    return parsed != null && parsed > 0;
  }

  // PIN validation
  static bool isValidPin(String pin) {
    final pinRegex = RegExp(r'^\d{4,6}$');
    return pinRegex.hasMatch(pin.trim());
  }

  // Name validation
  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\.\']{2,50}$");
    return nameRegex.hasMatch(name.trim());
  }

  // Account name validation
  static bool isValidAccountName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 1 || name.trim().length > 50) return false;
    return true;
  }

  // Category name validation
  static bool isValidCategoryName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 1 || name.trim().length > 50) return false;
    return true;
  }

  // Goal name validation
  static bool isValidGoalName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 1 || name.trim().length > 50) return false;
    return true;
  }

  // Notes validation
  static bool isValidNotes(String notes) {
    return notes.length <= 500;
  }

  // Date validation
  static bool isValidDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final minDate = DateTime(1900);
    final maxDate = DateTime(now.year + 10);
    return date.isAfter(minDate) && date.isBefore(maxDate);
  }

  // Future date validation
  static bool isValidFutureDate(DateTime? date) {
    if (date == null) return false;
    return date.isAfter(DateTime.now());
  }

  // Past or present date validation
  static bool isValidPastOrPresentDate(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now().add(const Duration(days: 1)));
  }

  // Currency code validation
  static bool isValidCurrencyCode(String code) {
    final currencyRegex = RegExp(r'^[A-Z]{3}$');
    return currencyRegex.hasMatch(code.trim().toUpperCase());
  }

  // Percentage validation (0-100)
  static bool isValidPercentage(String percentage) {
    if (percentage.trim().isEmpty) return false;
    final parsed = double.tryParse(percentage.trim());
    return parsed != null && parsed >= 0 && parsed <= 100;
  }

  // Password strength validation
  static PasswordStrength getPasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;
    
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasDigits = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    int strengthScore = 0;
    if (hasUppercase) strengthScore++;
    if (hasLowercase) strengthScore++;
    if (hasDigits) strengthScore++;
    if (hasSpecialCharacters) strengthScore++;
    if (password.length >= 12) strengthScore++;
    
    if (strengthScore >= 4) return PasswordStrength.strong;
    if (strengthScore >= 3) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  // Get validation error message
  static String? getAmountErrorMessage(String amount) {
    if (amount.trim().isEmpty) return 'Amount is required';
    if (!isValidAmount(amount)) return 'Enter a valid amount';
    return null;
  }

  static String? getPositiveAmountErrorMessage(String amount) {
    if (amount.trim().isEmpty) return 'Amount is required';
    if (!isValidPositiveAmount(amount)) return 'Enter a valid positive amount';
    return null;
  }

  static String? getEmailErrorMessage(String email) {
    if (email.trim().isEmpty) return null; // Email is optional in most cases
    if (!isValidEmail(email)) return 'Enter a valid email address';
    return null;
  }

  static String? getPhoneErrorMessage(String phone) {
    if (phone.trim().isEmpty) return null; // Phone is optional in most cases
    if (!isValidPhoneNumber(phone)) return 'Enter a valid phone number';
    return null;
  }

  static String? getNameErrorMessage(String name, {required String fieldName}) {
    if (name.trim().isEmpty) return '$fieldName is required';
    if (!isValidName(name)) return 'Enter a valid $fieldName';
    return null;
  }

  static String? getAccountNameErrorMessage(String name) {
    if (name.trim().isEmpty) return 'Account name is required';
    if (!isValidAccountName(name)) return 'Account name must be 1-50 characters';
    return null;
  }

  static String? getCategoryNameErrorMessage(String name) {
    if (name.trim().isEmpty) return 'Category name is required';
    if (!isValidCategoryName(name)) return 'Category name must be 1-50 characters';
    return null;
  }

  static String? getGoalNameErrorMessage(String name) {
    if (name.trim().isEmpty) return 'Goal name is required';
    if (!isValidGoalName(name)) return 'Goal name must be 1-50 characters';
    return null;
  }

  static String? getNotesErrorMessage(String notes) {
    if (!isValidNotes(notes)) return 'Notes must be less than 500 characters';
    return null;
  }

  static String? getPinErrorMessage(String pin) {
    if (pin.trim().isEmpty) return 'PIN is required';
    if (!isValidPin(pin)) return 'PIN must be 4-6 digits';
    return null;
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong;

  String get displayName {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
