import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to encourage local variables for instance fields used in only one method.
/// This rule checks for instance fields that are used in exactly one other
/// instance method of the class, suggesting
class PreferLocalVariableForSingleMethodInstanceFieldRule extends CustomRule {
  /// Constructor for the [PreferLocalVariableForSingleMethodInstanceFieldRule].
  PreferLocalVariableForSingleMethodInstanceFieldRule({
    required super.configs,
    super.ruleName = "prefer_local_variable_for_single_method_instance_field",
    super.ruleProblemMessage =
        "Instance field 'appears to be used only within the method",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((classNode) {
      // Get all non-static instance methods first for efficient lookup
      final instanceMethods = classNode.members
          .whereType<MethodDeclaration>()
          .where(
            (method) =>
                !method.name.lexeme.startsWith("_") &&
                !method.isStatic &&
                !method.isGetter &&
                !method.isSetter,
          )
          .toList();

      final instanceFieldsDeclarations = classNode.members
          .whereType<FieldDeclaration>();

      for (final fieldDeclaration in instanceFieldsDeclarations) {
        for (final variableDeclaration in fieldDeclaration.fields.variables) {
          var usageInOtherMethodsCount = 0;
          MethodDeclaration? firstUsingMethodNode;

          for (final methodNode in instanceMethods) {
            if (_isDirectGetterOrSetterForField(
              methodNode,
              variableDeclaration,
            )) {
              continue;
            }

            final usageVisitor = _FieldUsageVisitor(variableDeclaration);
            methodNode.body.accept(usageVisitor);

            if (!usageVisitor.foundUsage) {
              continue;
            }
            usageInOtherMethodsCount++;
            firstUsingMethodNode ??= methodNode;
            if (usageInOtherMethodsCount > 1) {
              break;
            }
          }

          if (usageInOtherMethodsCount <= 1 && firstUsingMethodNode != null) {
            reporter.atNode(fieldDeclaration, code);
          }
        }
      }
    });
  }

  /// Checks if the given [methodNode] is a direct getter or setter
  /// that primarily accesses the given [fieldElement].
  bool _isDirectGetterOrSetterForField(
    MethodDeclaration methodNode,
    VariableDeclaration fieldElement,
  ) {
    final actualMethodName = methodNode.name.lexeme;
    final actualFieldName = fieldElement.name.lexeme;

    var expectedPublicNameForField = actualFieldName;
    if (actualFieldName.startsWith("_") && actualFieldName.length > 1) {
      expectedPublicNameForField = actualFieldName.substring(1);
    }

    var isPotentialGetterOrSetterName = false;
    if (methodNode.isGetter || methodNode.isSetter) {
      if (actualFieldName.startsWith("_") &&
          actualMethodName == expectedPublicNameForField) {
        isPotentialGetterOrSetterName = true;
      } else if (!actualFieldName.startsWith("_") &&
          actualMethodName == actualFieldName) {
        isPotentialGetterOrSetterName = true;
      }
    }

    if (!isPotentialGetterOrSetterName) {
      return false;
    }

    final body = methodNode.body;

    final usageVisitor = _FieldUsageVisitor(fieldElement);
    body.accept(usageVisitor);

    return usageVisitor.foundUsage;
  }
}

class _FieldUsageVisitor extends RecursiveAstVisitor<void> {
  _FieldUsageVisitor(this._targetFieldElement);
  final VariableDeclaration _targetFieldElement;
  bool foundUsage = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (foundUsage) {
      return;
    }

    if (node.element?.name3 == _targetFieldElement.name.lexeme) {
      foundUsage = true;
    }

    super.visitSimpleIdentifier(node);
  }
}
