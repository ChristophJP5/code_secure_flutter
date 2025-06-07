import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/error/error.dart" hide LintCode;
import "package:analyzer/error/listener.dart";
import "package:analyzer/source/source_range.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:collection/collection.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Lint Rule to ensure that the return value of all non-void functions is checked or cast to void.
/// This rule checks for function, method, and constructor declarations.
/// It requires that the return value of non-void functions is either checked or cast to void.
class CheckReturnValueRule extends CustomRule {
  
  /// Constructor for the [CheckReturnValueRule].
  CheckReturnValueRule({
    required super.configs,
    super.ruleName = "check_return_value",
    super.ruleProblemMessage =
        "Check the return value of all non-void functions",
    super.correctionMessage =
        "CAdd a check for the return value of the function, cast it to void if the return value is not needed or add a comment explaining why it is not needed.",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _addDeclarationListener(
        context,
        node,
        node.functionExpression.body,
        node.name.lexeme,
        reporter,
      );
    });

    context.registry.addMethodDeclaration((node) {
      _addDeclarationListener(
        context,
        node,
        node.body,
        node.name.lexeme,
        reporter,
      );
    });

    context.registry.addConstructorDeclaration((node) {
      _addDeclarationListener(
        context,
        node,
        node.body,
        node.name?.lexeme,
        reporter,
      );
    });
  }

  void _addListenerWithoutVariableDeclaration(
    AstNode root,
    String? functionName,
    String? methodName,
    ErrorReporter reporter,
    MethodInvocation invocation,
  ) {
    final ifDeclaration = root.childEntities
        .whereType<IfStatement>()
        .firstWhereOrNull((ifStatement) {
          return ifStatement.expression.toSource().contains("$methodName(");
        });
    if (ifDeclaration != null) {
      reporter.atNode(
        invocation,
        createLintCode(
          problemMessage:
              'In "$functionName" check the return value of method "$methodName" in statement "${ifDeclaration.expression.toSource()}" ',
        ),
      );
      return;
    }
    final forDeclaration = root.childEntities
        .whereType<ForStatement>()
        .firstWhereOrNull((statement) {
          return statement.toSource().contains("$methodName(");
        });
    if (forDeclaration != null) {
      reporter.atNode(
        invocation,
        createLintCode(
          problemMessage:
              'In "$functionName" check the return value of method "$methodName" in for loop',
        ),
      );
      return;
    }
  }

  void _addDeclarationListener(
    CustomLintContext context,
    AstNode node,
    FunctionBody? body,
    String? functionName,
    ErrorReporter reporter,
  ) {
    if (body == null) {
      return;
    }

    // Add visitor to check usage of the function's return value
    context.registry.addMethodInvocation((invocation) {
      if (invocation.isCascaded) {
        return;
      }

      final returnType = _getReturnType(invocation);
      if (returnType == null || returnType == "void") {
        return;
      }

      if (!_isInSameScope(invocation, body)) {
        return;
      }

      if (_isVoidMethodInvocation(invocation) || _isCastToVoid(invocation)) {
        return;
      }

      final methodName = invocation.methodName.name;
      final root = body.childEntities.first as Block;
      final variableDeclaration = root.childEntities
          .whereType<VariableDeclarationStatement>()
          .firstWhereOrNull((variable) {
            return variable.toSource().contains("$methodName(");
          });
      if (variableDeclaration == null) {
        _addListenerWithoutVariableDeclaration(
          root,
          functionName,
          methodName,
          reporter,
          invocation,
        );
        return;
      }

      // We have a complex variable declaration, so we need to extract the variable name
      final variableName = variableDeclaration
          .toSource()
          .split("=")[0]
          .trim()
          .split(RegExp(r"\s+"))
          .last
          .trim();

      // we/i some how fucked up the extraction of the variable name
      if (variableName.isEmpty) {
        throw Exception(
          "Failed to extract variable name from VariableDeclarationStatement: ${variableDeclaration.toSource()} on method: $methodName",
        );
      }

      // Ensure Variable is checked by developer
      final isChecked = root.childEntities.any((entity) {
        if (entity is IfStatement) {
          return entity.expression.unParenthesized.toString().contains(
            variableName,
          );
        }
        if (entity is AssertStatement) {
          return entity.condition.unParenthesized.toString().contains(
            variableName,
          );
        }
        if (entity is AssertInitializer) {
          return entity.condition.unParenthesized.toString().contains(
            variableName,
          );
        }
        return false;
      });
      if (isChecked) {
        return;
      }

      reporter.atNode(
        invocation,
        createLintCode(
          problemMessage:
              'In "$functionName" Check the return value of method "$methodName" for variable "$variableName"',
        ),
      );
    });
  }

  bool _isInSameScope(AstNode node, FunctionBody body) {
    AstNode? current = node;
    const maxDepth = 200;
    var depth = 0;
    while (current != null) {
      if (depth++ >= maxDepth) {
        return false;
      }
      if (current == body) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _isVoidMethodInvocation(MethodInvocation invocation) {
    final staticType = invocation.staticType;
    return staticType == null || staticType.toString() == "void";
  }

  bool _isCastToVoid(Expression expression) {
    return expression is AsExpression && expression.type.toString() == "void";
  }

  String? _getReturnType(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.returnType?.type?.toString();
    } else if (node is MethodDeclaration) {
      return node.returnType?.type?.toString();
    } else if (node is MethodInvocation) {
      return node.staticType?.toString();
    } else if (node is ExpressionStatement) {
      return node.expression.staticType.toString();
    }
    return null;
  }

  @override
  List<Fix> getFixes() => [_AddCheckFix()];
}

class _AddCheckFix extends DartFix {
  String generateCheck(String parameterName, String parameterType) {
    if (parameterName.startsWith("List<") ||
        parameterName.startsWith("Map<") ||
        parameterName.startsWith("Set<")) {
      return '''
if($parameterName.isEmpty){
  throw Exception("$parameterName must not be empty, is: \$$parameterName");
}''';
    }
    switch (parameterType) {
      case "DateTime":
        return """
const DateTime ${parameterName}MinValue = DateTime(1970);
if($parameterName.isAfter(${parameterName}MinValue)){
  throw Exception("$parameterName must be after \$${parameterName}MinValue, is: \$$parameterName");
}
const DateTime ${parameterName}MaxValue = DateTime.now();
if($parameterName.isBefore(${parameterName}MaxValue)){
  throw Exception("$parameterName must be before \$${parameterName}MaxValue, is: \$$parameterName");
}
""";
      case "int":
        return """
const int ${parameterName}MinValue = 0;
if($parameterName <= ${parameterName}MinValue){
 throw Exception("$parameterName must be greater than \$${parameterName}MinValue, is: \$$parameterName");
}
const int ${parameterName}MaxValue = 0x20000000000000;
if($parameterName >= ${parameterName}MaxValue){
 throw Exception("$parameterName must be less than \$${parameterName}MaxValue, is: \$$parameterName");
}
""";
      case "double":
        return """
const double ${parameterName}MinValue = 0;
if(!$parameterName <= ${parameterName}MinValue){
 throw Exception("$parameterName must be greater than \$${parameterName}MinValue, is: \$$parameterName");
}
const double ${parameterName}MaxValue = double.maxFinite;
if(!$parameterName >= ${parameterName}MaxValue){
 throw Exception("$parameterName must be less than \$${parameterName}MaxValue, is: \$$parameterName");
}
""";
      case "String":
        return '''
if($parameterName.isEmpty){
  throw Exception("$parameterName must not be empty, is: \$$parameterName");
}''';
      default:
        return '''
if($parameterName == null){
  throw Exception("$parameterName must not be null, is: \$$parameterName");
}''';
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
          message: "Add check for $parameterName",
          priority: 1,
        )
        .addDartFileEdit((builder) {
          if (body is BlockFunctionBody) {
            builder.addSimpleInsertion(
              body.block.leftBracket.end,
              "\n  ${generateCheck(parameterName, parameterType)}\n",
            );
          } else if (body is ExpressionFunctionBody) {
            // need to convert to a function with a block body to use assert
            final expression = body.expression;
            final bodyText =
                " {\n  ${generateCheck(parameterName, parameterType)}\n  return ${expression.toSource()};\n}";
            builder.addSimpleReplacement(
              SourceRange(body.offset, body.length),
              bodyText,
            );
          }
        });
  }
}
