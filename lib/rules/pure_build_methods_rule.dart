import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// A lint that forbids side effects in widget `build` methods.
/// This rule checks for asynchronous operations and method invocations
/// that return `Future` or `Stream` types within the `build` method of Flutter widgets.
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - pure_build_methods:
///         error_severity: Error
/// ```
///
/// **BAD:**
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     analytics.logScreenView(name: 'MyWidget'); // Side effect
///     return Text('Hello World');
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Hello World');
///   }
///   
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     analytics.logScreenView(name: 'MyWidget');
///   }
/// }
/// ```
class PureBuildMethodsRule extends CustomRule {
  /// Creates a new instance of [PureBuildMethodsRule].
  PureBuildMethodsRule({
    required super.configs,
    super.ruleName = "pure_build_methods",
    super.ruleProblemMessage = "Side effects are forbidden in build methods.",
    super.correctionMessage =
        "Move this async call to initState, didChangeDependencies, or a state management listener.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != "build") {
        return;
      }

      final enclosingClass = node.parent;
      if (enclosingClass is! ClassDeclaration) {
        return;
      }

      final classType = enclosingClass.declaredFragment?.element.thisType;
      if (classType == null) {
        return;
      }
      const widgetChecker = TypeChecker.any([
        TypeChecker.fromName("StatelessWidget", packageName: "flutter"),
        TypeChecker.fromName("State", packageName: "flutter"),
      ]);
      if (!widgetChecker.isAssignableFromType(classType)) {
        return;
      }

      node.body.accept(
        _SideEffectVisitor(
          onSideEffect: (violatingNode) {
            reporter.atNode(violatingNode, code);
          },
        ),
      );
    });
  }
}

class _SideEffectVisitor extends RecursiveAstVisitor<void> {
  _SideEffectVisitor({required this.onSideEffect});

  final void Function(AstNode) onSideEffect;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onSideEffect(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final staticType = node.staticType;
    if (staticType == null) {
      return;
    }
    if (node.parent is ReturnStatement) {
      return;
    }
    onSideEffect(node);
    super.visitMethodInvocation(node);
  }
}
