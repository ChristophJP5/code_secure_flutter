import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Detects code that disables TLS certificate validation by assigning a callback
/// that always returns true to `HttpClient.badCertificateCallback`.
class RequireVerifiedSslCertificatesRule extends CustomRule {
  /// Constructor for the [RequireVerifiedSslCertificatesRule].
  RequireVerifiedSslCertificatesRule({
    required super.configs,
    super.ruleName = "require_verified_ssl_certificates",
    super.ruleProblemMessage =
        "Do not disable TLS certificate verification by returning true in badCertificateCallback.",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((node) {
      final propertyName = _extractPropertyName(node.leftHandSide);
      if (propertyName != "badCertificateCallback") {
        return;
      }

      if (!_isAlwaysTrueCallback(node.rightHandSide)) {
        return;
      }

      reporter.atNode(
        node.rightHandSide,
        createLintCode(
          problemMessage:
              "badCertificateCallback must validate the certificate. Remove the blanket `=> true` override.",
        ),
      );
    });
  }

  String? _extractPropertyName(Expression expression) {
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    }
    if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }
    if (expression is SimpleIdentifier) {
      return expression.name;
    }
    return null;
  }

  bool _isAlwaysTrueCallback(Expression expression) {
    if (expression is FunctionExpression) {
      final body = expression.body;
      if (body is ExpressionFunctionBody) {
        return body.expression is BooleanLiteral &&
            (body.expression as BooleanLiteral).value;
      }
      if (body is BlockFunctionBody) {
        for (final statement in body.block.statements) {
          if (statement is ReturnStatement) {
            final value = statement.expression;
            if (value is BooleanLiteral && value.value) {
              return true;
            }
          }
        }
      }
    }

    if (expression is FunctionExpressionInvocation) {
      return _isAlwaysTrueCallback(expression.function);
    }

    if (expression is ParenthesizedExpression) {
      return _isAlwaysTrueCallback(expression.expression);
    }

    return false;
  }
}
