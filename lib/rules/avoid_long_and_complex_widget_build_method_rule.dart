import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

const _widgetCheckerForComplexity = TypeChecker.any([
  TypeChecker.fromName("StatelessWidget", packageName: "flutter"),
  TypeChecker.fromName("State", packageName: "flutter"),
]);

/// A lint that flags `build` methods that are too complex.
/// This rule checks for the number of lines and nesting depth in the `build` method of Flutter widgets.
/// It helps maintain readability and manageability of widget build methods by enforcing limits on their complexity.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid_long_and_complex_widget_build_method:
///         error_severity: Warning
///         build_method_max_char_count: 800
/// ```
///
/// **BAD:**
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('My Screen'),
///       // Many widgets and complex logic in one method
///       // ...
///       // ...
///     ),
///     body: Column(
///       children: [
///         // Dozens of widgets with complex conditionals
///         // ...
///         // ...
///       ],
///     ),
///   );
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: _buildAppBar(),
///     body: _buildBody(),
///   );
/// }
///
/// Widget _buildAppBar() {
///   return AppBar(title: Text('My Screen'));
/// }
///
/// Widget _buildBody() {
///   return Column(
///     children: [
///       _buildHeader(),
///       _buildContent(),
///       _buildFooter(),
///     ],
///   );
/// }
/// ```
class AvoidLongAndComplexWidgetBuildMethodRule extends CustomRule {
  /// Creates a new instance of [AvoidLongAndComplexWidgetBuildMethodRule].
  AvoidLongAndComplexWidgetBuildMethodRule({
    required super.configs,
    super.ruleName = "avoid_long_and_complex_widget_build_method",
    super.ruleProblemMessage = "This build method is too complex.",
    super.correctionMessage =
        "Refactor parts of the widget tree into smaller, private build methods or, preferably, into separate StatelessWidget classes.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final maxLines = configs.getInt(code.name, "max-lines") ?? 80;
    final maxNestingDepth = configs.getInt(code.name, "max-nesting-depth") ?? 7;

    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != "build") {
        return;
      }

      final enclosingClass = node.parent;
      if (enclosingClass is! ClassDeclaration) {
        return;
      }

      final classType = enclosingClass.declaredFragment?.element.thisType;
      if (classType == null ||
          !_widgetCheckerForComplexity.isAssignableFromType(classType)) {
        return;
      }

      final lines = node.body.toSource().split("\n").length;
      if (lines > maxLines) {
        reporter.atNode(
          node,
          createLintCode(
            problemMessage:
                "Build method is too long: $lines lines, exceeds maximum of $maxLines.",
          ),
        );
      }

      node.body.accept(
        _NestingVisitor(
          nestingMaxDepth: maxNestingDepth,
          onNestingDetected: (nestedNode, depth) {
            reporter.atNode(
              nestedNode,
              createLintCode(
                problemMessage:
                    "Nesting depth of $depth exceeds maximum of $maxNestingDepth.",
              ),
            );
          },
        ),
      );
    });
  }
}

class _NestingVisitor extends UnifyingAstVisitor<void> {
  _NestingVisitor({
    required this.nestingMaxDepth,
    required this.onNestingDetected,
  });

  final int nestingMaxDepth;
  final void Function(AstNode, int depth) onNestingDetected;

  int _currentDepth = 0;

  @override
  void visitBlock(Block node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitBlock(node);
    _currentDepth--;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitConstructorDeclaration(node);
    _currentDepth--;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitInstanceCreationExpression(node);
    _currentDepth--;
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitConstructorName(node);
    _currentDepth--;
  }

  @override
  void visitIfStatement(IfStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitIfStatement(node);
    _currentDepth--;
  }

  @override
  void visitForStatement(ForStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitForStatement(node);
    _currentDepth--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _currentDepth++;
    if (_currentDepth > nestingMaxDepth) {
      onNestingDetected(node, _currentDepth);
      return;
    }
    super.visitWhileStatement(node);
    _currentDepth--;
  }
}
