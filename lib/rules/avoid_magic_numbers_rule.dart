import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Discourages unnamed numeric literals sprinkled through business logic.
/// Named constants communicate intent and make future tweaks safer.
class AvoidMagicNumbersRule extends CustomRule {
  /// Constructor for the [AvoidMagicNumbersRule].
  AvoidMagicNumbersRule({
    required super.configs,
    super.ruleName = "avoid_magic_numbers",
    super.ruleProblemMessage =
        "Replace magic numbers with named constants for clarity.",
    
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final allowedSet = _loadAllowedNumbers();
    final ignoreConstContexts =
        configs.getBool(code.name, "ignore_const_contexts") ?? true;
    final ignoreEnumValues =
        configs.getBool(code.name, "ignore_enum_values") ?? true;
    final ignoreSwitchCases =
        configs.getBool(code.name, "ignore_switch_cases") ?? true;

    void checkInteger(IntegerLiteral literal) {
      _handleLiteral(
        literal: literal,
        numericValue: literal.value,
        allowedSet: allowedSet,
        ignoreConstContexts: ignoreConstContexts,
        ignoreEnumValues: ignoreEnumValues,
        ignoreSwitchCases: ignoreSwitchCases,
        reporter: reporter,
      );
    }

    void checkDouble(DoubleLiteral literal) {
      _handleLiteral(
        literal: literal,
        numericValue: literal.value,
        allowedSet: allowedSet,
        ignoreConstContexts: ignoreConstContexts,
        ignoreEnumValues: ignoreEnumValues,
        ignoreSwitchCases: ignoreSwitchCases,
        reporter: reporter,
      );
    }

    context.registry.addIntegerLiteral(checkInteger);
    context.registry.addDoubleLiteral(checkDouble);
  }

  Set<num> _loadAllowedNumbers() {
    final configured = configs.getStringList(code.name, "allowed_numbers");
    if (configured == null || configured.isEmpty) {
      return {-1, 0, 0.5, 1, 2, 10};
    }
    final values = <num>{};
    for (final entry in configured) {
      final parsed = num.tryParse(entry);
      if (parsed != null) {
        values.add(parsed);
      }
    }
    return values;
  }

  void _handleLiteral({
    required Expression literal,
    required num? numericValue,
    required Set<num> allowedSet,
    required bool ignoreConstContexts,
    required bool ignoreEnumValues,
    required bool ignoreSwitchCases,
    required ErrorReporter reporter,
  }) {
    if (numericValue == null) {
      return;
    }

    if (_shouldIgnore(
      literal: literal,
      value: numericValue,
      allowedNumbers: allowedSet,
      ignoreConstContexts: ignoreConstContexts,
      ignoreEnumValues: ignoreEnumValues,
      ignoreSwitchCases: ignoreSwitchCases,
    )) {
      return;
    }

    reporter.atNode(
      literal,
      createLintCode(
        problemMessage:
            "Found magic number $numericValue. Move it into a named constant.",
      ),
    );
  }

  bool _shouldIgnore({
    required Expression literal,
    required num value,
    required Set<num> allowedNumbers,
    required bool ignoreConstContexts,
    required bool ignoreEnumValues,
    required bool ignoreSwitchCases,
  }) {
    if (allowedNumbers.contains(value)) {
      return true;
    }

    final lexical = literal.toSource().replaceAll("_", "");
    final lexicalNumber = num.tryParse(lexical);
    if (lexicalNumber != null && allowedNumbers.contains(lexicalNumber)) {
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

    if (_isConstContext(literal) && ignoreConstContexts) {
      return true;
    }

    final variableList = literal.thisOrAncestorOfType<VariableDeclarationList>();
    if (variableList != null && (variableList.isConst || variableList.isFinal)) {
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
