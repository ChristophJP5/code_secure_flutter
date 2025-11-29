import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Flags suspicious string literals that look like secrets or credentials.
/// Hard-coding auth tokens tends to leak them into git history forever.
class RequireSecureCredentialStorageRule extends CustomRule {
  /// Constructor for the [RequireSecureCredentialStorageRule].
  RequireSecureCredentialStorageRule({
    required super.configs,
    super.ruleName = "require_secure_credential_storage",
    super.ruleProblemMessage =
        "Possible credential is hard-coded. Store secrets securely instead.",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  static const _defaultCredentialKeywords = <String>{
    "password",
    "passwd",
    "pwd",
    "secret",
    "token",
    "apikey",
    "api_key",
    "clientsecret",
    "authorization",
    "client_secret",
    "jwt",
    "credential",
    "key",
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final suspiciousKeywords = _loadKeywords();
    final ignoredIdentifiers =
        configs.getStringList(code.name, "ignored_identifiers")?.toSet() ??
            const <String>{};
    final minLength = configs.getInt(code.name, "min_literal_length") ?? 8;

    context.registry.addVariableDeclaration((node) {
      final identifier = node.name.lexeme;
      if (ignoredIdentifiers.contains(identifier)) {
        return;
      }
      final initializer = node.initializer;
      final literalValue = _stringValue(initializer);
      if (literalValue == null) {
        return;
      }
      if (_looksLikeCredentialName(identifier, suspiciousKeywords) &&
          literalValue.length >= minLength) {
        reporter.atNode(
          initializer!,
          createLintCode(
            problemMessage:
                "'$identifier' looks like a credential and is assigned a literal. Move it to secure storage or environment variables.",
          ),
        );
        return;
      }
      if (_looksLikeCredentialValue(literalValue) &&
          literalValue.length >= minLength) {
        reporter.atNode(
          initializer!,
          createLintCode(
            problemMessage:
                "This literal matches credential patterns. Avoid committing secrets to source control.",
          ),
        );
      }
    });

    context.registry.addSetOrMapLiteral((node) {
      for (final element in node.elements) {
        if (element is! MapLiteralEntry) {
          continue;
        }
        final keyValue = _stringValue(element.key);
        final valueValue = _stringValue(element.value);
        if (keyValue == null || valueValue == null) {
          continue;
        }
        if (!_looksLikeCredentialName(keyValue, suspiciousKeywords)) {
          continue;
        }
        if (valueValue.length < minLength) {
          continue;
        }
        reporter.atNode(
          element.value,
          createLintCode(
            problemMessage:
                "Map entry '$keyValue' stores what looks like credentials inline. Externalize secrets instead.",
          ),
        );
      }
    });
  }

  Set<String> _loadKeywords() {
    final configured = configs.getStringList(code.name, "suspicious_keywords");
    if (configured == null || configured.isEmpty) {
      return _defaultCredentialKeywords;
    }
    return configured.map((e) => e.toLowerCase()).toSet();
  }

  bool _looksLikeCredentialName(String identifier, Set<String> keywords) {
    final lower = identifier.toLowerCase();
    return keywords.any(lower.contains);
  }

  bool _looksLikeCredentialValue(String literal) {
    if (literal.contains("BEGIN PRIVATE KEY")) {
      return true;
    }
    if (literal.startsWith("AKIA") && literal.length > 16) {
      return true;
    }
    final tokenLike = RegExp(
      r"^(sk|pk|rk|ya29)_[0-9a-z_\-=/+]{8,}",
      caseSensitive: false,
    );
    if (tokenLike.hasMatch(literal)) {
      return true;
    }
    final hexLike = RegExp(r"^[A-Fa-f0-9]{32,}$");
    return hexLike.hasMatch(literal);
  }

  String? _stringValue(Expression? expression) {
    if (expression is StringLiteral) {
      return expression.stringValue;
    }
    if (expression is AdjacentStrings) {
      final values = expression.strings
          .map((e) => e.stringValue)
          .whereType<String>()
          .toList();
      if (values.length == expression.strings.length) {
        return values.join();
      }
    }
    if (expression is SimpleStringLiteral) {
      return expression.value;
    }
    return null;
  }
}
