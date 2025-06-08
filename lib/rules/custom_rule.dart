import "package:analyzer/error/error.dart" hide LintCode;
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// A custom lint rule for Dart that can be extended to implement specific
/// linting behavior.
abstract class CustomRule extends DartLintRule {
  /// Creates a new instance of [CustomRule].
  CustomRule({
    required this.configs,
    required String ruleName,
    String ruleProblemMessage = "",
    String correctionMessage = "",
    ErrorSeverity errorSeverity = ErrorSeverity.WARNING,
  }) : super(
         code: LintCode(
           name: ruleName,
           problemMessage: ruleProblemMessage,
           correctionMessage: correctionMessage,
           errorSeverity: configs.getErrorSeverity(ruleName) ?? errorSeverity,
         ),
       );

  /// Configuration for the lint rule.
  final CustomLintConfigs configs;

  /// generates a [LintCode] instance based on the provided parameters.
  LintCode createLintCode({
    String? name,
    String? problemMessage,
    String? correctionMessage,
    ErrorSeverity? errorSeverity,
  }) => LintCode(
    name: name ?? code.name,
    problemMessage: problemMessage ?? code.problemMessage,
    correctionMessage: correctionMessage ?? code.correctionMessage,
    errorSeverity: errorSeverity ?? code.errorSeverity,
  );
}
