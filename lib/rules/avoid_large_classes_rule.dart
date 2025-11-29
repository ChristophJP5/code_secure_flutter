import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Encourages splitting massive classes into smaller, testable units.
class AvoidLargeClassesRule extends CustomRule {
  /// Constructor for the [AvoidLargeClassesRule].
  AvoidLargeClassesRule({
    required super.configs,
    super.ruleName = "avoid_large_classes",
    super.ruleProblemMessage =
        "Class exceeds configured size limits. Break it into focused units.",
    
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final maxMembers = configs.getInt(code.name, "max_members") ?? 20;
    final maxLines = configs.getInt(code.name, "max_lines") ?? 400;
    final lineInfo = resolver.lineInfo;

    context.registry.addClassDeclaration((node) {
      final memberCount = node.members.length;
      final startLine = lineInfo.getLocation(node.offset).lineNumber;
      final endLine = lineInfo.getLocation(node.end).lineNumber;
      final span = endLine - startLine + 1;

      final exceedsMembers = memberCount > maxMembers;
      final exceedsLines = span > maxLines;

      if (!exceedsMembers && !exceedsLines) {
        return;
      }

      final problems = <String>[];
      if (exceedsMembers) {
        problems.add("members ($memberCount > $maxMembers)");
      }
      if (exceedsLines) {
        problems.add("lines ($span > $maxLines)");
      }

      reporter.atNode(
        node,
        createLintCode(
          problemMessage:
              "Class '${node.name.lexeme}' is too large: ${problems.join(" and ")}.",
        ),
      );
    });
  }
}
