import "package:analyzer/dart/ast/token.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Flags comment blocks that look like commented-out Dart code.
/// Encourages deleting dead code or extracting it into feature flags instead of
/// leaving large commented blobs behind.
class AvoidCommentedOutCodeRule extends CustomRule {
  /// Constructor for the [AvoidCommentedOutCodeRule].
  AvoidCommentedOutCodeRule({
    required super.configs,
    super.ruleName = "avoid_commented_out_code",
    super.ruleProblemMessage = "Remove commented-out code.",
  });

  static final _keywordPattern = RegExp(
    r"\b(if|for|while|switch|case|return|class|final|await|async|else|try|catch)\b",
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      Token? token = unit.beginToken;
      while (token != null && token.type != TokenType.EOF) {
        _inspectToken(token, reporter);
        token = token.next;
      }
    });
  }

  void _inspectToken(Token token, ErrorReporter reporter) {
    if (token.type != TokenType.MULTI_LINE_COMMENT &&
        token.type != TokenType.SINGLE_LINE_COMMENT) {
      return;
    }

    final text = token.lexeme;
    final minLines = configs.getInt(code.name, "min_consecutive_lines") ?? 3;
    final minScore = configs.getInt(code.name, "min_detection_score") ?? 2;
    // final ignorePrefixes = configs.getStringList(code.name, "ignore_prefixes") ??
    //     const ["// TODO", "// FIXME", "/* TODO", "/* FIXME"];

    // if (_isIgnored(text, ignorePrefixes)) {
    //   return;
    // }

    if (_looksLikeCode(text, minLines, minScore)) {
      reporter.atOffset(
        offset: token.offset,
        length: token.length,
        errorCode: createLintCode(
          problemMessage:
              "Commented-out code detected. Consider removing it or using feature flags.",
        ),
      );
    }
  }

  // bool _isIgnored(String raw, List<String> ignorePrefixes) {
  //   final trimmed = raw.trimLeft();
  //   for (final prefix in ignorePrefixes) {
  //     if (trimmed.startsWith(prefix)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  bool _looksLikeCode(
    String raw,
    int minLines,
    int minScore,
  ) {
    var cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return false;
    }

    cleaned = cleaned
        .replaceAll(RegExp(r"^/\*+|\*+/"), "")
        .replaceAll(RegExp(r"^\s*// ?", multiLine: true), "")
        .replaceAll(RegExp(r"^\s*\* ?", multiLine: true), "")
        .trim();

    final lines = cleaned.split("\n").map((line) => line.trim()).toList();
    final nonEmptyLines = lines.where((line) => line.isNotEmpty).toList();
    if (nonEmptyLines.length < minLines) {
      return false;
    }

    var score = 0;
    if (_keywordPattern.hasMatch(cleaned)) {
      score++;
    }
    if (cleaned.contains(";") || cleaned.contains("=>")) {
      score++;
    }
    if (RegExp("[{}()]").hasMatch(cleaned)) {
      score++;
    }

    return score >= minScore;
  }
}
