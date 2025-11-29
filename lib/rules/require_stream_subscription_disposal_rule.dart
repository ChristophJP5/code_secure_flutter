import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/type.dart";
import "package:analyzer/error/error.dart";
import "package:analyzer/error/listener.dart";
import "package:code_secure_flutter/extensions/custom_lint_config_extension.dart";
import "package:code_secure_flutter/rules/custom_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

const _stateChecker = TypeChecker.fromName("State", packageName: "flutter");

/// Ensures every `StreamSubscription` owned by a `State` subclass is cancelled
/// inside `dispose()`. Forgetting to cancel leaks listeners and keeps widgets
/// alive much longer than intended.
class RequireStreamSubscriptionDisposalRule extends CustomRule {
  /// Constructor for the [RequireStreamSubscriptionDisposalRule].
  RequireStreamSubscriptionDisposalRule({
    required super.configs,
    super.ruleName = "require_stream_subscription_disposal",
    super.ruleProblemMessage =
        "Stream subscriptions must be cancelled inside dispose().",
    super.errorSeverity = ErrorSeverity.ERROR,
  });

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final classType = node.declaredFragment?.element.thisType;
      if (classType == null || !_stateChecker.isAssignableFromType(classType)) {
        return;
      }

      final ignoredNames =
          configs.getStringList(code.name, "ignored_field_names")?.toSet() ??
              const <String>{};
      final subscriptions = _collectSubscriptionFields(node, ignoredNames);
      if (subscriptions.isEmpty) {
        return;
      }

      final disposeMethod = _findDispose(node);
      if (disposeMethod == null) {
        final requireDispose =
            configs.getBool(code.name, "require_dispose_override") ?? true;
        if (!requireDispose) {
          return;
        }
        for (final subscription in subscriptions) {
          reporter.atNode(
            subscription,
            createLintCode(
              problemMessage:
                  "StreamSubscription '${subscription.name.lexeme}' is never cancelled because dispose() is missing.",
            ),
          );
        }
        return;
      }

      final cancelledNames = _collectCancellations(
        disposeMethod,
        subscriptions.map((s) => s.name.lexeme).toSet(),
      );
      for (final subscription in subscriptions) {
        final name = subscription.name.lexeme;
        if (cancelledNames.contains(name)) {
          continue;
        }
        reporter.atNode(
          subscription,
          createLintCode(
            problemMessage:
                "StreamSubscription '$name' must call cancel() inside dispose().",
          ),
        );
      }
    });
  }

  List<VariableDeclaration> _collectSubscriptionFields(
    ClassDeclaration node,
    Set<String> ignoredNames,
  ) {
    final subscriptions = <VariableDeclaration>[];
    for (final member in node.members) {
      if (member is! FieldDeclaration || member.isStatic) {
        continue;
      }
      final variableList = member.fields;
      for (final variable in variableList.variables) {
        final name = variable.name.lexeme;
        if (ignoredNames.contains(name)) {
          continue;
        }
        final type =
            variable.declaredFragment?.element.type ?? variableList.type?.type;
        if (_isStreamSubscription(type)) {
          subscriptions.add(variable);
        }
      }
    }
    return subscriptions;
  }

  MethodDeclaration? _findDispose(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is! MethodDeclaration) {
        continue;
      }
      if (member.name.lexeme == "dispose") {
        return member;
      }
    }
    return null;
  }

  Set<String> _collectCancellations(
    MethodDeclaration disposeMethod,
    Set<String> targetNames,
  ) {
    final visitor = _SubscriptionCancellationVisitor(targetNames);
    disposeMethod.body.accept<void>(visitor);
    return visitor.cancelled;
  }

  bool _isStreamSubscription(DartType? type) {
    if (type == null) {
      return false;
    }
    final display = type.getDisplayString();
    return display == "StreamSubscription" ||
        display.startsWith("StreamSubscription<");
  }
}

class _SubscriptionCancellationVisitor extends RecursiveAstVisitor<void> {
  _SubscriptionCancellationVisitor(this.targetNames);

  final Set<String> targetNames;
  final Set<String> cancelled = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != "cancel") {
      super.visitMethodInvocation(node);
      return;
    }
    final targetName = _extractTargetName(node.target ?? node.realTarget);
    if (targetName != null && targetNames.contains(targetName)) {
      cancelled.add(targetName);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final baseName = _extractTargetName(node.target);
    if (baseName != null && targetNames.contains(baseName)) {
      for (final section in node.cascadeSections) {
        if (section is MethodInvocation &&
            section.methodName.name == "cancel") {
          cancelled.add(baseName);
        }
      }
    }
    super.visitCascadeExpression(node);
  }

  String? _extractTargetName(Expression? expression) {
    if (expression == null) {
      return null;
    }
    if (expression is SimpleIdentifier) {
      return expression.name;
    }
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    }
    if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }
    return null;
  }
}
