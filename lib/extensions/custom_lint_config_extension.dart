import "package:analyzer/error/error.dart";
import "package:collection/collection.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Extension for CustomLintConfigs to provide easy access to custom lint configurations.
extension CustomLintConfigExtension on CustomLintConfigs {
  /// Retrieves a double value from the custom lint configuration based on the rule name and function name.
  int? getInt(String ruleName, String variableName) {
    return int.tryParse(getValue(ruleName, variableName).toString());
  }

  /// Retrieves a double value from the custom lint configuration based on the rule name and function name.
  double? getDouble(String ruleName, String variableName) {
    return double.tryParse(getValue(ruleName, variableName).toString());
  }

  /// Retrieves a string value from the custom lint configuration based on the rule name and function name.
  String? getString(String ruleName, String variableName) {
    return getValue(ruleName, variableName)?.toString();
  }

  /// Retrieves a boolean value from the custom lint configuration based on the rule name and function name.
  bool? getBool(String ruleName, String variableName) {
    final value = getValue(ruleName, variableName);
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == "true";
    }
    return null;
  }

  /// Retrieves a list of strings from the custom lint configuration based on the rule name and function name.
  List<String>? getStringList(String ruleName, String variableName) {
    final value = getValue(ruleName, variableName);
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(",").map((e) => e.trim()).toList();
    }
    return null;
  }

  /// Retrieves an enum value from the custom lint configuration based on the rule name and function name.
  T? getEnum<T>(String ruleName, String variableName, List<T> values) {
    final value = getValue(ruleName, variableName);
    if (value is T) {
      return value;
    }
    if (value is String) {
      return values.firstWhereOrNull(
        (e) => e.toString().toLowerCase() == value.toLowerCase(),
      );
    }
    return null;
  }

  /// Retrieves the error severity from the custom lint configuration based on the rule name.
  ErrorSeverity? getErrorSeverity(String ruleName) {
    final enumValue = getEnum<ErrorSeverity>(
      ruleName,
      "error_severity",
      ErrorSeverity.values,
    );
    // print(
    //   "CustomLintConfigExtension.getErrorSeverity: $ruleName -> $enumValue",
    // );
    return enumValue;
  }

  /// Retrieves a value from the custom lint configuration based on the rule name and function name.
  dynamic getValue(String ruleName, String variableName) {
    final config = rules[ruleName];
    if (config == null) {
      return null;
    }
    if (config.json[variableName] == null) {
      return null;
    }
    return config.json[variableName];
  }
}
