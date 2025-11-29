import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Ensures every boolean parameter is documented with a short explanation.
/// Bool parameters are notoriously opaque (e.g. `update(true, false)`), so we
/// require a short comment/doc entry to explain the intent or trade-off.
class AvoidBooleanParametersRule extends CustomRule {
  /// Constructor for the [AvoidBooleanParametersRule].
  AvoidBooleanParametersRule({
    required super.configs,
    super.ruleName = "avoid_boolean_parameters",
    super.ruleProblemMessage =
        "Document boolean parameters to explain why a flag is used.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _checkParameters(node.functionExpression.parameters, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _checkParameters(node.parameters, reporter);
    });

    context.registry.addConstructorDeclaration((node) {
      _checkParameters(node.parameters, reporter);
    });
  }

  void _checkParameters(
    FormalParameterList? parameterList,
    ErrorReporter reporter,
  ) {
    if (parameterList == null || parameterList.parameters.isEmpty) {
      return;
    }

    final minCommentLength =
        configs.getInt(code.name, "min_comment_length") ?? 12;
    final allowedNames = configs.getStringList(
          code.name,
          "allowed_parameter_names",
        ) ??
        const [];

    for (final parameter in parameterList.parameters) {
      final element = parameter.declaredFragment?.element;
      if (element == null) {
        continue;
      }
      final parameterType = element.type;
      if (!parameterType.isDartCoreBool) {
        continue;
      }

      final name = parameter.name?.lexeme;
      if (name == null || allowedNames.contains(name)) {
        continue;
      }

      if (_hasMeaningfulComment(parameter, minCommentLength)) {
        continue;
      }

      reporter.atNode(
        parameter,
        createLintCode(
          problemMessage:
              "Boolean parameter '$name' lacks an explanation comment.",
        ),
      );
    }
  }

  bool _hasMeaningfulComment(FormalParameter parameter, int minLength) {
    final buffer = StringBuffer();
    for (Token? token = parameter.beginToken.precedingComments;
        token != null;
        token = token.next) {
      buffer.writeln(token.lexeme);
    }

    return _isMeaningful(buffer.toString(), minLength);
  }

  bool _isMeaningful(String? raw, int minLength) {
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final normalized = raw
        .replaceAll(RegExp(r"^\s*/// ?", multiLine: true), "")
        .replaceAll(RegExp(r"^\s*// ?", multiLine: true), "")
        .replaceAll(RegExp(r"/\*|\*/"), " ")
        .trim();
    if (normalized.isEmpty) {
      return false;
    }

    return normalized.length >= minLength;
  }
}
