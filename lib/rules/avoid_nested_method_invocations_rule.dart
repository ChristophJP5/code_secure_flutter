import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Guards against extremely long method chains (`foo().bar().baz().qux()...`).
/// Deep chains hide side-effects and make debugging painful, so we encourage
/// extracting intermediate values or helper methods.
class AvoidNestedMethodInvocationsRule extends CustomRule {
  /// Constructor for the [AvoidNestedMethodInvocationsRule].
  AvoidNestedMethodInvocationsRule({
    required super.configs,
    super.ruleName = "avoid_nested_method_invocations",
    super.ruleProblemMessage = "Method chaining depth exceeded the allowed maximum.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (_isPartOfLargerInvocation(node)) {
        return;
      }
      _reportIfTooDeep(node, reporter);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (_isPartOfLargerInvocation(node)) {
        return;
      }
      _reportIfTooDeep(node, reporter);
    });
  }

  bool _isPartOfLargerInvocation(AstNode node) {
    final parent = node.parent;
    return parent is MethodInvocation ||
        parent is FunctionExpressionInvocation ||
        parent is CascadeExpression;
  }

  void _reportIfTooDeep(Expression expression, ErrorReporter reporter) {
    final maxDepth = configs.getInt(code.name, "max_chain_depth") ?? 4;
    final depth = _calculateDepth(expression);
    if (depth <= maxDepth) {
      return;
    }

    reporter.atNode(
      expression,
      createLintCode(
        problemMessage:
            "Method chain depth $depth exceeds allowed maximum of $maxDepth. Split the chain into intermediate helpers.",
      ),
    );
  }

  int _calculateDepth(Expression expression) {
    var depth = 0;
    Expression? current = expression;
    final visited = <Expression>{};

    while (current != null) {
      if (!visited.add(current)) {
        break;
      }

      if (current is MethodInvocation) {
        depth++;
        current = current.target ?? current.realTarget;
        continue;
      }

      if (current is FunctionExpressionInvocation) {
        depth++;
        current = current.function;
        continue;
      }

      if (current is PropertyAccess) {
        depth++;
        current = current.target;
        continue;
      }

      if (current is PrefixedIdentifier) {
        depth++;
        current = current.prefix;
        continue;
      }

      if (current is CascadeExpression) {
        depth++;
        current = current.target;
        continue;
      }

      break;
    }

    return depth;
  }
}
