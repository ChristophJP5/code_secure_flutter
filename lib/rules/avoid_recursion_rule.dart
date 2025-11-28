import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element2.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to avoid direct recursion in functions and methods.
/// This rule checks for function and method declarations that call themselves
/// or their own class methods, which can lead to complex flow constructs and
/// potential stack overflow issues if not handled properly.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid_recursion:
///         error_severity: Warning
/// ```
///
/// **BAD:**
/// ```dart
/// int factorial(int n) {
///   if (n <= 1) return 1;
///   return n * factorial(n - 1); // Recursive call
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// int factorial(int n) {
///   int result = 1;
///   for (int i = 2; i <= n; i++) {
///     result *= i;
///   }
///   return result;
/// }
/// ```
class AvoidRecursionRule extends CustomRule {
  /// Constructor for the [AvoidRecursionRule].
  AvoidRecursionRule({
    required super.configs,
    super.ruleName = "avoid_recursion",
    super.ruleProblemMessage = "Avoid complex flow constructs as recursion, "
        "which can lead to stack overflow or unintended behavior.",
    super.correctionMessage =
        "Consider refactoring to use an iterative approach or ensure the recursion has a clear base case and is intended.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        node,
        node.functionExpression.body,
        [
          node.name.lexeme,
        ],
        reporter,
      );
    });

    context.registry.addMethodDeclaration((node) {
      final parent = node.parent is ClassDeclaration
          ? node.parent! as ClassDeclaration
          : null;
      _addDeclarationListener(
        node,
        node.body,
        [
          node.name.lexeme,
          if (parent?.name.lexeme != null) parent!.name.lexeme,
        ],
        reporter,
      );
    });

    context.registry.addConstructorDeclaration((node) {
      _addDeclarationListener(
        node,
        node.body,
        [
          node.returnType.name,
        ],
        reporter,
      );
    });
  }

  void _addDeclarationListener(
    AstNode node,
    FunctionBody? body,
    List<String> _,
    ErrorReporter reporter,
  ) {
    if (body == null) {
      return;
    }

    // Resolve the element of the current declaration.
    final target = switch (node) {
      FunctionDeclaration(:final declaredFragment) => declaredFragment?.element,
      MethodDeclaration(:final declaredFragment) => declaredFragment?.element,
      ConstructorDeclaration(:final declaredFragment) =>
        declaredFragment?.element,
      _ => null,
    };

    if (target == null) {
      return;
    }

    body.accept<void>(
      _RecursionVisitor(
        target: target,
        onRecursiveCall: (recursiveNode) {
          reporter.atNode(recursiveNode, code);
        },
      ),
    );
  }
}

class _RecursionVisitor extends RecursiveAstVisitor<void> {
  _RecursionVisitor({
    required this.target,
    required this.onRecursiveCall,
  });

  final ExecutableElement2 target;
  final void Function(AstNode node) onRecursiveCall;

  bool _matches(Element2? element) =>
      element is ExecutableElement2 && element == target;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_matches(node.methodName.element)) {
      onRecursiveCall(node.methodName);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_matches(node.element)) {
      onRecursiveCall(node.function);
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_matches(node.constructorName.element)) {
      onRecursiveCall(node.constructorName);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    if (_matches(node.element)) {
      onRecursiveCall(node);
    }
    super.visitRedirectingConstructorInvocation(node);
  }
}
