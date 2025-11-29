import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Warns when `Random()` (from `dart:math`) is used instead of `Random.secure()`
/// or a cryptographically secure RNG. Default `Random` is predictable and not
/// appropriate for tokens, OTPs, salts, etc.
class RequireSecureRandomNumberGeneratorRule extends CustomRule {
  /// Constructor for the [RequireSecureRandomNumberGeneratorRule].
  RequireSecureRandomNumberGeneratorRule({
    required super.configs,
    super.ruleName = "require_secure_random_number_generator",
    super.ruleProblemMessage =
        "Use Random.secure() or a crypto secure RNG instead of Random().",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final ignoredVariables =
        configs.getStringList(code.name, "ignored_identifiers")?.toSet() ??
            const <String>{};

    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName;
      final typeName = constructorName.type.type?.getDisplayString();
      if (typeName != "Random") {
        return;
      }
      final named = constructorName.name?.name;
      if (named == "secure") {
        return;
      }

      final variableName = _enclosingVariableName(node);
      if (variableName != null && ignoredVariables.contains(variableName)) {
        return;
      }

      reporter.atNode(
        node,
        createLintCode(
          problemMessage:
              "Random() uses a predictable algorithm. Prefer Random.secure() or crypto library RNGs for secrets.",
        ),
      );
    });
  }

  String? _enclosingVariableName(InstanceCreationExpression node) {
    final variable = node.thisOrAncestorOfType<VariableDeclaration>();
    return variable?.name.lexeme;
  }
}
