import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Flags public (non-underscored) fields that remain mutable.
/// Mutable shared state is a breeding ground for flaky bugs.
class AvoidPublicMutableStateRule extends CustomRule {
  /// Constructor for the [AvoidPublicMutableStateRule].
  AvoidPublicMutableStateRule({
    required super.configs,
    super.ruleName = "avoid_public_mutable_state",
    super.ruleProblemMessage =
        "Public fields should be final/const to avoid accidental mutation.",
    
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final ignoredFieldNames =
        configs.getStringList(code.name, "ignored_fields")?.toSet() ??
            const <String>{};
    final ignoredTypes = configs
            .getStringList(code.name, "ignored_types")
            ?.map((e) => e.toLowerCase())
            .toSet() ??
        const <String>{};
    final ignoredClasses =
        configs.getStringList(code.name, "ignored_classes")?.toSet() ??
            const <String>{};

    context.registry.addFieldDeclaration((node) {
      final enclosing = node.parent;
      final className =
          enclosing is ClassDeclaration ? enclosing.name.lexeme : null;
      if (className != null && ignoredClasses.contains(className)) {
        return;
      }
      _checkVariableList(
        node.fields,
        reporter,
        ignoredFieldNames,
        ignoredTypes,
      );
    });

    context.registry.addTopLevelVariableDeclaration((node) {
      _checkVariableList(
        node.variables,
        reporter,
        ignoredFieldNames,
        ignoredTypes,
      );
    });
  }

  void _checkVariableList(
    VariableDeclarationList variableList,
    ErrorReporter reporter,
    Set<String> ignoredFields,
    Set<String> ignoredTypes,
  ) {
    final isImmutable = variableList.isFinal || variableList.isConst;
    if (isImmutable) {
      return;
    }

    for (final variable in variableList.variables) {
      final name = variable.name.lexeme;
      if (name.startsWith("_")) {
        continue;
      }
      if (ignoredFields.contains(name)) {
        continue;
      }
      final type =
          variable.declaredFragment?.element.type ?? variableList.type?.type;
      final typeName = type?.getDisplayString().toLowerCase();
      if (typeName != null && ignoredTypes.contains(typeName)) {
        continue;
      }

      reporter.atNode(
        variable,
        createLintCode(
          problemMessage:
              "Public field '$name' is mutable. Mark it final or expose it via getters.",
        ),
      );
    }
  }
}
