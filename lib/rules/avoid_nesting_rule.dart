import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to avoid deeply nested structures in functions and methods.
/// This rule checks for function and method declarations that contain
/// nested blocks, if statements, for loops, and while loops that exceed a
/// specified maximum nesting depth.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid_nesting:
///         error_severity: Warning
///         max_nesting_level: 3
/// ```
///
/// **BAD:**
/// ```dart
/// void processData(List<int> items) {
///   if (items.isNotEmpty) {
///     for (var item in items) {
///       if (item > 0) {
///         if (item % 2 == 0) {
///           if (item < 100) {
///             // Too many nesting levels
///           }
///         }
///       }
///     }
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void processData(List<int> items) {
///   if (items.isEmpty) {
///     return;
///   }
///   for (var item in items) {
///     if (item <= 0) {
///       continue; // Skip non-positive items
///     }
///     if (item >= 100) {
///       continue; // limit processing to items less than 100
///     }
///     if (item.isEven) {
///       
///     }
///   }
/// }
/// ```
class AvoidNestingRule extends CustomRule {
  
  /// Constructor for the [AvoidNestingRule].
  AvoidNestingRule({
    required super.configs,
    super.ruleName = "avoid_nesting",
    super.ruleProblemMessage = "Avoid to deeply nested structures in functions and methods.",
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
    const defaultRemoveValue = 4;
    final configNestingMaxDepth =
        configs.getInt(code.name, "nesting_max_depth") ?? 3;
    final nestingMaxDepth = defaultRemoveValue + configNestingMaxDepth;
    body?.accept<void>(
      _NestingVisitor(
        nestingMaxDepth: nestingMaxDepth,
        onNestingDetected: (node, depth) {
          final code = createLintCode(
            problemMessage: """
Avoid to deeply nested structures in functions and methods. 
Nesting depth is ${depth - defaultRemoveValue}, maximum allowed is ${nestingMaxDepth - defaultRemoveValue}.""",
          );
          reporter.atNode(node, code);
        },
      ),
    );
  }
}

class _NestingVisitor extends RecursiveAstVisitor<void> {
  _NestingVisitor({required this.nestingMaxDepth, required this.onNestingDetected});

  final int nestingMaxDepth;
  final void Function(AstNode, int depth) onNestingDetected;

  int _currentDepth = 0;

  @override
  void visitBlock(Block node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
    }
    super.visitBlock(node);
    _currentDepth--;
  }

  @override
  void visitIfStatement(IfStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
    }
    super.visitIfStatement(node);
    _currentDepth--;
  }

  @override
  void visitForStatement(ForStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
    }
    super.visitForStatement(node);
    _currentDepth--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
    }
    super.visitWhileStatement(node);
    _currentDepth--;
  }
}

