import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to avoid direct recursion in functions and methods.
/// This rule checks for function and method declarations that call themselves
/// or their own class methods, which can lead to complex flow constructs and
/// potential stack overflow issues if not handled properly.
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
      _addDeclarationListener(node, node.functionExpression.body, [
        node.name.lexeme,
      ], reporter);
    });

    context.registry.addMethodDeclaration((node) {
      final parent = node.parent is ClassDeclaration
          ? node.parent! as ClassDeclaration
          : null;
      _addDeclarationListener(node, node.body, [
        node.name.lexeme,
        if (parent?.name.lexeme != null) parent!.name.lexeme,
      ], reporter);
    });

    context.registry.addConstructorDeclaration((node) {
      _addDeclarationListener(node, node.body, [
        node.returnType.name,
      ], reporter);
    });
  }

  void _addDeclarationListener(
    AstNode node,
    FunctionBody? body,
    List<String> names,
    ErrorReporter reporter,
  ) {
    final functionBody = body?.toSource();
    if (functionBody == null) {
      return;
    }
    for (final name in names) {
      if (functionBody.contains("$name(") ||
          functionBody.contains("$name.call")) {
        reporter.atNode(node, code);
      }
    }
  }
}
