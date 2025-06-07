import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:analyzer/source/source_range.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// A lint that flags the use of `async void`.
/// This rule checks for both top-level functions and methods within classes.
/// It reports an error if an `async` function or method has a return type of `void`.
class AvoidAsyncVoidRule extends CustomRule {
  
  /// Creates a new instance of [AvoidAsyncVoidRule].
  AvoidAsyncVoidRule({
    required super.configs,
  }):super(
    ruleName: "avoid_async_void",
    ruleProblemMessage: "Avoid using 'async void'.",
    correctionMessage:
        "Return 'Future<void>' to allow for error handling and proper awaiting. Unhandled exceptions in 'async void' methods will crash the app.",
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Check top-level function declarations
    context.registry.addFunctionDeclaration((node) {
      _checkFunction(
        isAsync: node.functionExpression.body.isAsynchronous,
        returnType: node.returnType,
        errorNode: node,
        reporter: reporter,
      );
    });

    // Check method declarations within classes
    context.registry.addMethodDeclaration((node) {
      _checkFunction(
        isAsync: node.body.isAsynchronous,
        returnType: node.returnType,
        errorNode: node,
        reporter: reporter,
      );
    });
  }

  void _checkFunction({
    required bool isAsync,
    required TypeAnnotation? returnType,
    required AstNode errorNode,
    required ErrorReporter reporter,
  }) {
    if (!isAsync) {
      return;
    }

    // The return type is `void` if it's explicitly declared or if it's null
    // (implicit dynamic, often treated as void in this context).
    final isVoid = returnType == null || returnType.type.toString() == "void";

    if (isVoid) {
      // Report the error if the function is async and returns void
      reporter.atNode(errorNode, code);
    }
  }

  @override
  List<Fix> getFixes() => [_ConvertToFutureVoidFix()];
}

/// Fix that converts async void methods to async Future\<void>
class _ConvertToFutureVoidFix extends DartFix {
  _ConvertToFutureVoidFix();

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addFunctionDeclaration((node) {
      if (!node.functionExpression.body.isAsynchronous) {
        return;
      }
      if (analysisError.source.fullName !=
          node.declaredElement?.source.fullName) {
        return;
      }
      if (node.offset != analysisError.offset) {
        return;
      }

      reporter
          .createChangeBuilder(
            message: "Convert to 'Future<void>'",
            priority: 80,
          )
          .addDartFileEdit((builder) {
            if (node.returnType == null) {
              builder.addSimpleInsertion(node.name.offset, "Future<void> ");
            } else {
              builder.addSimpleReplacement(
                SourceRange(node.returnType!.offset, node.returnType!.length),
                "Future<void>",
              );
            }
          });
    });

    context.registry.addMethodDeclaration((node) {
      if (!node.body.isAsynchronous) {
        return;
      }
      if (analysisError.source.fullName !=
          node.declaredElement?.source.fullName) {
        return;
      }
      if (node.offset != analysisError.offset) {
        return;
      }

      reporter
          .createChangeBuilder(
            message: "Convert to 'Future<void>'",
            priority: 80,
          )
          .addDartFileEdit((builder) {
            if (node.returnType == null) {
              // Add return type if none exists
              builder.addSimpleInsertion(node.name.offset, "Future<void> ");
            } else {
              // Replace existing return type
              builder.addSimpleReplacement(
                SourceRange(node.returnType!.offset, node.returnType!.length),
                "Future<void>",
              );
            }
          });
    });
  }
}
