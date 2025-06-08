import "package:code_secure_flutter/rules/avoid_long_and_complex_functions_rule.dart";
import "package:code_secure_flutter/rules/avoid_long_and_complex_widget_build_method_rule.dart";
import "package:code_secure_flutter/rules/avoid_nesting_rule.dart";
import "package:code_secure_flutter/rules/avoid_recursion_rule.dart";
import "package:code_secure_flutter/rules/check_return_value_rule.dart";
import "package:code_secure_flutter/rules/loops_require_fixed_bound_rule.dart";
import "package:code_secure_flutter/rules/prefer_local_variable_for_single_method_instance_field_rule.dart";
import "package:code_secure_flutter/rules/pure_build_methods_rule.dart";
import "package:code_secure_flutter/rules/require_mounted_check_in_async_callbacks_rule.dart";
import "package:code_secure_flutter/rules/require_parameter_assert_rule.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

/// Creates a Custom Lint Plugin for Flutter that checks function parameters for assertions.
PluginBase createPlugin() => _ExampleLinter();

class _ExampleLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      AvoidLongAndComplexFunctionsRule(configs: configs),
      AvoidNestingRule(configs: configs),
      AvoidRecursionRule(configs: configs),
      CheckReturnValueRule(configs: configs),
      AvoidLongAndComplexWidgetBuildMethodRule(configs: configs),
      LoopsRequireFixedBoundRule(configs: configs),
      RequireParameterAssertRule(configs: configs),
      PreferLocalVariableForSingleMethodInstanceFieldRule(configs: configs),
      PureBuildMethodsRule(configs: configs),
      RequireMountedCheckInAsyncCallbacksRule(configs: configs),
    ];
  }
}
