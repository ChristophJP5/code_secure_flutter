import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Pushes developers to introduce parameter objects/builders when signatures
/// become unwieldy. More than a handful of parameters typically screams for a
/// refactor.
class AvoidTooManyParameterRule extends CustomRule {
  /// Constructor for the [AvoidTooManyParameterRule].
  AvoidTooManyParameterRule({
    required super.configs,
    super.ruleName = "avoid_too_many_parameters",
    super.ruleProblemMessage =
        "This declaration accepts too many parameters to stay readable.",
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final maxParams = configs.getInt(code.name, "max_parameter_count") ?? 5;
    final ignoredNames =
        configs.getStringList(code.name, "ignored_function_names")?.toSet() ??
            const <String>{};
    final ignoreOverrides =
        configs.getBool(code.name, "ignore_override_methods") ?? true;

    context.registry.addFunctionDeclaration((node) {
      _checkParameterCount(
        parameters: node.functionExpression.parameters,
        declarationName: node.name.lexeme,
        declarationKind: "Function",
        isOverride: false,
        maxParams: maxParams,
        ignoredNames: ignoredNames,
        ignoreOverrides: ignoreOverrides,
        reporter: reporter,
        reportNode: node.functionExpression.parameters,
      );
    });

    context.registry.addMethodDeclaration((node) {
      _checkParameterCount(
        parameters: node.parameters,
        declarationName: node.name.lexeme,
        declarationKind: "Method",
        isOverride: node.metadata.any(_isOverrideAnnotation),
        maxParams: maxParams,
        ignoredNames: ignoredNames,
        ignoreOverrides: ignoreOverrides,
        reporter: reporter,
        reportNode: node.parameters,
      );
    });

    context.registry.addConstructorDeclaration((node) {
      final constructorName = _constructorName(node);
      _checkParameterCount(
        parameters: node.parameters,
        declarationName: constructorName,
        declarationKind: "Constructor",
        isOverride: false,
        maxParams: maxParams,
        ignoredNames: ignoredNames,
        ignoreOverrides: ignoreOverrides,
        reporter: reporter,
        reportNode: node.parameters,
      );
    });
  }

  void _checkParameterCount({
    required FormalParameterList? parameters,
    required String declarationName,
    required String declarationKind,
    required bool isOverride,
    required int maxParams,
    required Set<String> ignoredNames,
    required bool ignoreOverrides,
    required ErrorReporter reporter,
    required AstNode? reportNode,
  }) {
    if (parameters == null || reportNode == null) {
      return;
    }
    if (ignoredNames.contains(declarationName)) {
      return;
    }
    if (ignoreOverrides && isOverride) {
      return;
    }

    final totalParams = parameters.parameters.length;
    if (totalParams <= maxParams) {
      return;
    }

    reporter.atNode(
      reportNode,
      createLintCode(
        problemMessage:
            "$declarationKind '$declarationName' defines $totalParams parameters (max $maxParams). Introduce a parameter object or split the API.",
      ),
    );
  }

  bool _isOverrideAnnotation(Annotation annotation) {
    final identifier = annotation.name;
    if (identifier is SimpleIdentifier) {
      return identifier.name == "override";
    }
    return false;
  }

  String _constructorName(ConstructorDeclaration node) {
    final baseName = node.returnType.name;
    final named = node.name;
    if (named == null) {
      return baseName;
    }
    return "$baseName.${named.lexeme}";
  }
}
