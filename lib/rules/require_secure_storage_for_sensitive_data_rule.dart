import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Discourages storing secrets via SharedPreferences and similar plain-text stores.
/// Encourages the use of FlutterSecureStorage or platform keystores instead.
class RequireSecureStorageForSensitiveDataRule extends CustomRule {
  /// Constructor for the [RequireSecureStorageForSensitiveDataRule].
  RequireSecureStorageForSensitiveDataRule({
    required super.configs,
    super.ruleName = "require_secure_storage_for_sensitive_data",
    super.ruleProblemMessage =
        "Do not store sensitive data in SharedPreferences. Use FlutterSecureStorage instead.",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  static const _defaultSensitiveKeys = <String>{
    "password",
    "secret",
    "token",
    "apikey",
    "refresh",
    "session",
  };

  static const _sharedPreferencesType = "SharedPreferences";
  static const _mutatingPrefMethods = <String>{
    "setString",
    "setInt",
    "setBool",
    "setDouble",
    "setStringList",
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final sensitiveKeys = _loadSensitiveKeys();
    final ignoredKeys =
        configs.getStringList(code.name, "ignored_keys")?.toSet() ??
            const <String>{};

    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (!_mutatingPrefMethods.contains(methodName)) {
        return;
      }
      final targetExpression = node.realTarget ?? node.target;
      if (!_isSharedPreferencesTarget(targetExpression)) {
        return;
      }
      if (node.argumentList.arguments.isEmpty) {
        return;
      }
      final keyExpression = node.argumentList.arguments.first;
      final keyValue = _stringValue(keyExpression);
      if (keyValue == null) {
        return;
      }
      if (ignoredKeys.contains(keyValue)) {
        return;
      }
      if (!_looksSensitive(keyValue, sensitiveKeys)) {
        return;
      }
      reporter.atNode(
        node.methodName,
        createLintCode(
          problemMessage:
              "Key '$keyValue' should not be persisted via SharedPreferences. Use secure storage instead.",
        ),
      );
    });
  }

  bool _isSharedPreferencesTarget(Expression? target) {
    final type = target?.staticType;
    if (type == null) {
      return false;
    }
    return type.getDisplayString() == _sharedPreferencesType;
  }

  bool _looksSensitive(String key, Set<String> keywords) {
    final lower = key.toLowerCase();
    return keywords.any(lower.contains);
  }

  Set<String> _loadSensitiveKeys() {
    final configured = configs.getStringList(code.name, "sensitive_keys");
    if (configured == null || configured.isEmpty) {
      return _defaultSensitiveKeys;
    }
    return configured.map((e) => e.toLowerCase()).toSet();
  }

  String? _stringValue(Expression? expression) {
    if (expression is StringLiteral) {
      return expression.stringValue;
    }
    if (expression is AdjacentStrings) {
      final pieces = expression.strings
          .map((e) => e.stringValue)
          .whereType<String>()
          .toList();
      if (pieces.length == expression.strings.length) {
        return pieces.join();
      }
    }
    return null;
  }
}
