import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/error/error.dart" show AnalysisError, ErrorSeverity;
import "package:analyzer/error/listener.dart";
import "package:analyzer/source/source_range.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to ensure each function/method parameter has an assertion.
/// This rule checks for parameters in function, method, and constructor declarations.
/// It requires at least one 'assert' statement or a custom validation check for each parameter.
/// If a parameter is not validated, it reports a ERROR with a suggestion to add an assertion.
/// It also provides a fix to automatically add an assertion based on the parameter type.
class ParameterAssertRequiredRule extends CustomRule {
  
  /// Constructor for the [ParameterAssertRequiredRule].
  ParameterAssertRequiredRule({
    required super.configs,
    super.ruleName = "parameter_assert_required",
    super.ruleProblemMessage =
        "Parameter should have a 'assert' statement for validation check.",
    super.correctionMessage =
        "Add an 'assert' statement validating the parameter or ensure a custom check exists.",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  static final _excludeParameterName = <String>["this"];
  static final _excludeParameterType = <String>[
    "Key",
    "Key?",
    "WidgetRef",
    "WidgetRef?",
    "BuildContext",
    "BuildContext?",
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        node,
        node.functionExpression.parameters,
        node.functionExpression.body,
        reporter,
      );
    });

    context.registry.addMethodDeclaration((node) {
      _addDeclarationListener(node, node.parameters, node.body, reporter);
    });

    context.registry.addConstructorDeclaration((node) {
      _addDeclarationListener(node, node.parameters, node.body, reporter);
    });
  }

  void _addDeclarationListener(
    AstNode node,
    FormalParameterList? parameterList,
    FunctionBody? body,
    ErrorReporter reporter,
  ) {
    if (parameterList == null || parameterList.parameters.isEmpty) {
      return;
    }

    void validateParameters([bool Function(String)? checkParameterName]) {
      final parameters = parameterList.parameters;
      for (final parameter in parameters) {
        final parameterName = parameter.name?.lexeme;
        if (parameterName == null) {
          continue;
        }
        if (checkParameterName != null && checkParameterName(parameterName)) {
          continue;
        }
        if (_excludeParameterName.contains(parameterName)) {
          continue;
        }

        final parameterType = parameter.declaredElement?.type.toString();
        if (_excludeParameterType.contains(parameterType)) {
          continue;
        }
        final configExcludeTypes =
            configs.getStringList(code.name, "exclude_parameter_types") ?? [];

        if (configExcludeTypes.contains(parameterType)) {
          continue;
        }

        final isNamedWithDefault =
            parameter.isNamed &&
            parameter is DefaultFormalParameter &&
            parameter.defaultValue != null;
        if (isNamedWithDefault) {
          continue;
        }

        reporter.atNode(
          node,
          createLintCode(
            problemMessage:
                "Parameter $parameterName should have a 'assert' statement for validation check.",
          ),
          data: [parameterName, parameterType],
        );
      }
    }

    if (body is! BlockFunctionBody) {
      validateParameters();
      return;
    }

    final blockFunctionBody = body;
    final assertedParameterNames = <String>{};
    for (final statement in blockFunctionBody.block.statements) {
      if (statement is! AssertStatement) {
        continue;
      }

      final condition = statement.condition;
      final identifierVisitor = _IdentifierVisitor();
      condition.accept(identifierVisitor);

      for (final paramId in identifierVisitor.identifiers) {
        assertedParameterNames.add(paramId.name);
      }
    }

    validateParameters(assertedParameterNames.contains);
  }

  @override
  List<Fix> getFixes() => [_AddAssertTodoFix()];
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final List<SimpleIdentifier> identifiers = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node);
    super.visitSimpleIdentifier(node);
  }
}

class _AddAssertTodoFix extends DartFix {
  String generateAssertCheck(String parameterName, String parameterType) {
    if (parameterName.startsWith("List<") ||
        parameterName.startsWith("Map<") ||
        parameterName.startsWith("Set<")) {
      return 'assert($parameterName.isNotEmpty, "$parameterName must not be empty, is: \$$parameterName");';
    }
    switch (parameterType) {
      case "DateTime":
        return """
const DateTime ${parameterName}MinValue = DateTime(1970);
assert($parameterName.isAfter(${parameterName}MinValue), "$parameterName must be after \$${parameterName}MinValue, is: \$$parameterName");
const DateTime ${parameterName}MaxValue = DateTime.now();
assert($parameterName.isBefore(${parameterName}MaxValue), "$parameterName must be before \$${parameterName}MaxValue, is: \$$parameterName");
""";
      case "int":
        return """
const int ${parameterName}MinValue = 0;
assert($parameterName > ${parameterName}MinValue, "$parameterName must be greater than \$${parameterName}MinValue, is: \$$parameterName");
const int ${parameterName}MaxValue = 0x20000000000000;
assert($parameterName < ${parameterName}MaxValue, "$parameterName must be less than \$${parameterName}MaxValue, is: \$$parameterName");""";
      case "double":
        return """
const double ${parameterName}MinValue = 0;
assert($parameterName > ${parameterName}MinValue, "$parameterName must be greater than \$${parameterName}MinValue, is: \$$parameterName");
const double ${parameterName}MaxValue = double.maxFinite;
assert($parameterName < ${parameterName}MaxValue, "$parameterName must be less than \$${parameterName}MaxValue, is: \$$parameterName");
""";
      case "String":
        return 'assert($parameterName.isNotEmpty, "$parameterName must not be empty, is: \$$parameterName");';
      default:
        return 'assert($parameterName != null, "$parameterName must not be null, is: \$$parameterName");';
    }
  }

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
        node.declaredElement,
        reporter,
        analysisError,
      );
    });
    context.registry.addMethodDeclaration((node) {
      _addDeclarationListener(
        node.body,
        node.name,
        node.declaredElement,
        reporter,
        analysisError,
      );
    });
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        node.functionExpression.body,
        node.name,
        node.declaredElement,
        reporter,
        analysisError,
      );
    });
  }

  void _addDeclarationListener(
    FunctionBody body,
    Token name,
    ExecutableElement? declaredElement,
    ChangeReporter reporter,
    AnalysisError analysisError,
  ) {
    final method = declaredElement;
    if (method == null) {
      return;
    }

    final sourceRange = SourceRange(method.nameOffset, name.length);
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
            builder.addSimpleInsertion(
              body.block.leftBracket.end,
              "\n  ${generateAssertCheck(parameterName, parameterType)}\n",
            );
          } else if (body is ExpressionFunctionBody) {
            // need to convert to a function with a block body to use assert
            final expression = body.expression;
            final bodyText =
                " {\n  ${generateAssertCheck(parameterName, parameterType)}\n  return ${expression.toSource()};\n}";
            builder.addSimpleReplacement(
              SourceRange(body.offset, body.length),
              bodyText,
            );
          }
        });
  }
}
