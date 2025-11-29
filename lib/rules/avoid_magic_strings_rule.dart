import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Encourages replacing ad-hoc string literals with named constants.
class AvoidMagicStringsRule extends CustomRule {
  /// Constructor for the [AvoidMagicStringsRule].
  AvoidMagicStringsRule({
    required super.configs,
    super.ruleName = "avoid_magic_strings",
    super.ruleProblemMessage =
        "Replace this magic string with a named constant or enum.",
    
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final allowedStrings = _loadAllowedStrings();
    final minLength = configs.getInt(code.name, "min_length") ?? 3;
    final ignoreConstContexts =
        configs.getBool(code.name, "ignore_const_contexts") ?? true;
    final ignoreEnumValues =
        configs.getBool(code.name, "ignore_enum_values") ?? true;
    final ignoreAnnotations =
        configs.getBool(code.name, "ignore_annotation_arguments") ?? true;
    final ignoreMapKeys =
        configs.getBool(code.name, "ignore_map_keys") ?? true;
    final ignoreSwitchCases =
        configs.getBool(code.name, "ignore_switch_cases") ?? true;
    final ignoreDirectives =
        configs.getBool(code.name, "ignore_import_export_directives") ?? true;

    void handleLiteral(Expression literal, String? value) {
      if (value == null) {
        return;
      }
      if (value.length < minLength && !allowedStrings.contains(value)) {
        return;
      }

      if (_shouldIgnore(
        literal: literal,
        value: value,
        allowedStrings: allowedStrings,
        ignoreConstContexts: ignoreConstContexts,
        ignoreEnumValues: ignoreEnumValues,
        ignoreAnnotations: ignoreAnnotations,
        ignoreMapKeys: ignoreMapKeys,
        ignoreSwitchCases: ignoreSwitchCases,
        ignoreDirectives: ignoreDirectives,
      )) {
        return;
      }

      final preview = value.length > 32 ? "${value.substring(0, 29)}..." : value;
      reporter.atNode(
        literal,
        createLintCode(
          problemMessage:
              "Found magic string '$preview'. Extract it into a const or enum to avoid drift.",
        ),
      );
    }

    context.registry.addSimpleStringLiteral((literal) {
      handleLiteral(literal, literal.value);
    });
    context.registry.addAdjacentStrings((node) {
      final fragments = node.strings
          .map((part) => part.stringValue)
          .whereType<String>()
          .toList();
      if (fragments.length != node.strings.length) {
        return;
      }
      handleLiteral(node, fragments.join());
    });
  }

  Set<String> _loadAllowedStrings() {
    final configured = configs.getStringList(code.name, "allowed_strings");
    if (configured == null || configured.isEmpty) {
      return {
        "",
        " ",
        ".",
        ",",
        ":",
        ";",
        "-",
        "_",
      };
    }
    return configured.toSet();
  }

  bool _shouldIgnore({
    required Expression literal,
    required String value,
    required Set<String> allowedStrings,
    required bool ignoreConstContexts,
    required bool ignoreEnumValues,
    required bool ignoreAnnotations,
    required bool ignoreMapKeys,
    required bool ignoreSwitchCases,
    required bool ignoreDirectives,
  }) {
    if (allowedStrings.contains(value)) {
      return true;
    }

    final parent = literal.parent;
    if (ignoreDirectives && parent is UriBasedDirective) {
      return true;
    }

    if (ignoreAnnotations &&
        literal.thisOrAncestorOfType<Annotation>() != null) {
      return true;
    }

    if (ignoreEnumValues &&
        literal.thisOrAncestorOfType<EnumConstantDeclaration>() != null) {
      return true;
    }

    if (ignoreSwitchCases &&
        literal.thisOrAncestorOfType<SwitchMember>() != null) {
      return true;
    }

    if (ignoreMapKeys &&
        parent is MapLiteralEntry &&
        identical(parent.key, literal)) {
      return true;
    }

    if (ignoreConstContexts && _isConstContext(literal)) {
      return true;
    }

    return false;
  }

  bool _isConstContext(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is TypedLiteral && current.constKeyword != null) {
        return true;
      }
      if (current is InstanceCreationExpression && current.isConst) {
        return true;
      }
      if (current is ConstructorDeclaration && current.constKeyword != null) {
        return true;
      }
      if (current is VariableDeclarationList && current.isConst) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }
}
