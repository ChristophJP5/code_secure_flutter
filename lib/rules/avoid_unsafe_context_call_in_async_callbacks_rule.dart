import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element2.dart";
import "package:analyzer/error/error.dart" hide LintCode;
import "package:analyzer/error/listener.dart";
import "package:analyzer/source/source_range.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// A lint that requires a `mounted` check for operations after an `await`.
/// This rule checks for asynchronous methods in classes that extend `State`
/// and ensures that any calls to `setState`, `context`, or similar operations
///
/// **Configuration in `analysis_options.yaml`:**
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid_unsafe_context_call_in_async_callbacks:
///         error_severity: Error
/// ```
///
/// **BAD:**
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   void initState() {
///     super.initState();
///     fetchData().then((_) {
///       setState(() { // No mounted check before setState
///         isLoaded = true;
///       });
///     });
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   void initState() {
///     super.initState();
///     fetchData().then((_) {
///       if (!mounted) {
///         return;
///       }
///       setState(() {
///         isLoaded = true;
///       });
///     });
///   }
/// }
/// ```
class AvoidUnsafeContextCallInAsyncCallbacksRule extends CustomRule {
  /// Creates a new instance of [AvoidUnsafeContextCallInAsyncCallbacksRule].
  AvoidUnsafeContextCallInAsyncCallbacksRule({
    required super.configs,
    super.ruleName = "avoid_unsafe_context_call_in_async_callbacks",
    super.ruleProblemMessage =
        'The widget may be disposed of after an async gap. This call is not guarded by a "mounted" check.',
    super.correctionMessage =
        "Wrap this call in `if (mounted) { ... }` to prevent runtime errors.",
  });

  static const _stateChecker = TypeChecker.fromName(
    "State",
    packageName: "flutter",
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      final enclosingClass = node.parent;
      if (enclosingClass is! ClassDeclaration) {
        return;
      }

      final classType = enclosingClass.declaredFragment?.element.thisType;
      if (classType == null || !_stateChecker.isAssignableFromType(classType)) {
        return;
      }

      if (!node.body.isAsynchronous) {
        return;
      }

      node.body.accept(
        _MountedCheckVisitor(
          onUnsafeCall: (violatingNode) {
            reporter.atNode(violatingNode, code);
          },
        ),
      );
    });
  }
}

class _MountedCheckVisitor extends RecursiveAstVisitor<void> {
  _MountedCheckVisitor({required this.onUnsafeCall});

  final void Function(AstNode) onUnsafeCall;
  final List<AwaitExpression> _awaits = [];

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _awaits.add(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == "setState") {
      _checkForUnsafeCall(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "context") {
      _checkForUnsafeCall(node);
    }
    super.visitSimpleIdentifier(node);
  }

  void _checkForUnsafeCall(AstNode node) {
    if (_awaits.isEmpty) {
      return;
    }

    // If this call happens before the first await, it's safe.
    if (_awaits.every((a) => node.offset < a.offset)) {
      return;
    }

    if (_isGuardedByMounted(node)) {
      return;
    }
    onUnsafeCall(node);
  }

  bool _isGuardedByMounted(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is MethodDeclaration) {
        break;
      }
      if (parent is BlockFunctionBody || parent is Block) {
        final statements = parent is BlockFunctionBody
            ? parent.block.statements
            : (parent as Block).statements;

        for (final statement in statements) {
          if (statement is! IfStatement) {
            continue;
          }
          if (statement.offset >= node.offset) {
            continue;
          }
          if (statement.elseStatement != null) {
            continue;
          }

          final condition = statement.expression;
          if (condition is! PrefixExpression) {
            continue;
          }
          if (condition.operator.type != TokenType.BANG) {
            continue;
          }
          if (condition.operand is! SimpleIdentifier) {
            continue;
          }
          if ((condition.operand as SimpleIdentifier).name != "mounted") {
            continue;
          }

          final thenBlock = statement.thenStatement;
          if (thenBlock is ReturnStatement ||
              (thenBlock is Block &&
                  thenBlock.statements.any((s) => s is ReturnStatement))) {
            return true;
          }
        }
      }
      // Check if we are inside an `if (mounted) { ... }` block
      if (parent is IfStatement) {
        final condition = parent.expression;
        if (condition is SimpleIdentifier &&
            condition.name == "mounted" &&
            parent.thenStatement.childEntities.contains(node)) {
          return true;
        }
      }

      parent = parent.parent;
    }
    return false;
  }

  List<Fix> getFixes() => [_AddMountedCheckFix()];
}

class _AddMountedCheckFix extends DartFix {
  String get fixKind => "Add mounted check";

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        node.functionExpression.body,
        node.name,
        node.declaredFragment?.element,
        reporter,
        analysisError,
      );
    });
    context.registry.addMethodDeclaration((node) {
      _addDeclarationListener(
        node.body,
        node.name,
        node.declaredFragment?.element,
        reporter,
        analysisError,
      );
    });
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        node.functionExpression.body,
        node.name,
        node.declaredFragment?.element,
        reporter,
        analysisError,
      );
    });
  }

  void _addDeclarationListener(
    FunctionBody body,
    Token name,
    ExecutableElement2? declaredElement,
    ChangeReporter reporter,
    AnalysisError analysisError,
  ) {
    final method = declaredElement;
    if (method == null) {
      return;
    }

    final sourceRange = SourceRange(method.name3?.length ?? 0, name.length);
    if (!analysisError.sourceRange.intersects(sourceRange)) {
      return;
    }
    if (analysisError.data is! List) {
      return;
    }

    final data = analysisError.data! as List<Object?>;
    if (data.isEmpty) {
      return;
    }
    final parameterName = data[0];
    if (parameterName is! String || parameterName.isEmpty) {
      return;
    }
    final parameterType = data[1];
    if (parameterType is! String || parameterType.isEmpty) {
      return;
    }

    reporter
        .createChangeBuilder(
      message: "Add assert for $parameterName",
      priority: 1,
    )
        .addDartFileEdit((builder) {
      if (body is BlockFunctionBody) {
        builder
          ..addSimpleInsertion(
            body.block.leftBracket.end,
            "\n if(!mounted) { \n return; \n } \n",
          )
          ..addSimpleInsertion(body.block.rightBracket.end, "\n");
      } else if (body is ExpressionFunctionBody) {
        // need to convert to a function with a block body to use assert
        final expression = body.expression;
        final bodyText =
            " \n  if(!mounted) { \n return; \n } \n return ${expression.toSource()};\n";
        builder.addSimpleReplacement(
          SourceRange(body.offset, body.length),
          bodyText,
        );
      }
    });
  }
}
