import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to ensure loops have a fixed bound to avoid infinite loops.
/// This rule checks for `while` and `do` loops in function, method, and constructor declarations.
/// It requires that the loop condition is a fixed bound, such as a comparison with an integer literal.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - loops_require_fixed_bound:
///         error_severity: Error
/// ```
///
/// **BAD:**
/// ```dart
/// void infiniteLoop() {
///   while (true) {
///     // This could run forever
///     doSomething();
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void boundedLoop() {
///   final maxIterations = 100;
///   int i = 0;
///   
///   while (i < maxIterations && !isDone()) {
///     doSomething();
///     i++;
///   }
/// }
/// ```
class LoopsRequireFixedBoundRule extends CustomRule {
  
  /// Constructor for the [LoopsRequireFixedBoundRule].
  LoopsRequireFixedBoundRule({
    required super.configs,
    super.ruleName = "loops_require_fixed_bound",
    super.ruleProblemMessage =
        "Loops should have a fixed bound to avoid infinite loops",
    super.correctionMessage = "Consider using a loop with a defined limit.",
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

    context.registry.addConstructorDeclaration((node) {
      _addDeclarationListener(node, node.body, reporter);
    });
  }

  void _addDeclarationListener(
    AstNode node,
    FunctionBody? body,
    ErrorReporter reporter,
  ) {
    if (body == null) {
      return;
    }

    body.accept<void>(
      _LoopVisitor(
        onUnboundedLoopFound: (loop) {
          reporter.atNode(loop, code);
        },
      ),
    );
  }
}

/// Visitor that identifies loops without fixed bounds
class _LoopVisitor extends RecursiveAstVisitor<void> {
  _LoopVisitor({required this.onUnboundedLoopFound});

  final void Function(AstNode) onUnboundedLoopFound;

  @override
  void visitWhileStatement(WhileStatement node) {
    if (!_hasFixedBoundCondition(node.condition)) {
      onUnboundedLoopFound(node);
    }
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    if (!_hasFixedBoundCondition(node.condition)) {
      onUnboundedLoopFound(node);
    }
    super.visitDoStatement(node);
  }
}

bool _hasFixedBoundCondition(Expression condition) {
  if (condition is BinaryExpression) {
    final op = condition.operator.type;
    return (op.isRelationalOperator || op.isEqualityOperator) &&
        (condition.leftOperand is IntegerLiteral ||
            condition.rightOperand is IntegerLiteral);
  }
  return false;
}
