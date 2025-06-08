import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to avoid functions that are too long or complex
/// This rule checks for function and method declarations that exceed a specified maximum character count or cyclomatic complexity.
/// It helps maintain code readability and manageability by enforcing limits on function size and complexity.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid_long_and_complex_functions:
///         error_severity: Warning
///         function_max_char_count: 1100
///         function_max_complexity: 15
/// ```
///
/// **BAD:**
/// ```dart
/// void doEverythingAtOnce() {
///   // 100+ lines of code with multiple responsibilities
///   // Complex nested logic
///   // Multiple different operations
///   // ...
///   // ...
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void validateInput() {
///   // 10-15 lines focused on input validation
/// }
///
/// void processData() {
///   // 30 - 50 lines focused on data processing
/// }
///
/// void saveResults() {
///   // 10-30 lines focused on saving results
/// }
/// ```
class AvoidLongAndComplexFunctionsRule extends CustomRule {
  
  /// Constructor for the [AvoidLongAndComplexFunctionsRule].
  AvoidLongAndComplexFunctionsRule({
    required super.configs,
    super.ruleName = "avoid_long_and_complex_functions",
    super.ruleProblemMessage = "Avoid functions that are too long or complex",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(node, node.functionExpression.body, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _addDeclarationListener(node, node.body, reporter);
    });
  }

  void _addDeclarationListener(
    AstNode node,
    FunctionBody? body,
    ErrorReporter reporter,
  ) {
    final functionBody = body?.toSource();
    if (functionBody == null) {
      return;
    }
    _checkCodeComplexity(node, functionBody, reporter);
    _checkCodeLength(node, functionBody, reporter);
  }

  void _checkCodeLength(
    AstNode node,
    String functionBody,
    ErrorReporter reporter,
  ) {
    final functionMaxCharCount =
        configs.getInt(code.name, "function_max_char_count") ?? 1100;
    if (functionBody.length <= functionMaxCharCount) {
      return;
    }
    reporter.atNode(
      node,
      createLintCode(
        problemMessage:
            "Avoid functions that are too long. Function is ${functionBody.length} characters, maximum allowed is $functionMaxCharCount characters.",
      ),
    );
  }

  void _checkCodeComplexity(
    AstNode node,
    String functionBody,
    ErrorReporter reporter,
  ) {
    final functionMaxComplexity =
        configs.getInt(code.name, "function_max_complexity") ?? 15;
    final complexity = _calculateCyclomaticComplexity(functionBody);
    if (complexity <= functionMaxComplexity) {
      return;
    }
    reporter.atNode(
      node,
      createLintCode(
        problemMessage:
            "Avoid functions that are too complex. Function has a complexity of $complexity, maximum allowed is $functionMaxComplexity complexity.",
      ),
    );
  }

  int _calculateCyclomaticComplexity(String functionBody) {
    final keywords = [
      "if",
      "for",
      "while",
      "case",
      "catch",
      "&&",
      "||",
      "?:",
      "??",
      "else",
    ];
    var complexity = 1;
    for (final keyword in keywords) {
      complexity += functionBody.split(keyword).length - 1;
    }
    return complexity;
  }
}
