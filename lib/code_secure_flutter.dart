import "package:code_secure_flutter/rules/avoid_boolean_parameters_rule.dart";
import "package:code_secure_flutter/rules/avoid_commented_out_code_rule.dart";
import "package:code_secure_flutter/rules/avoid_impure_build_methods_rule.dart";
import "package:code_secure_flutter/rules/avoid_large_classes_rule.dart";
import "package:code_secure_flutter/rules/avoid_long_and_complex_functions_rule.dart";
import "package:code_secure_flutter/rules/avoid_long_and_complex_widget_build_method_rule.dart";
import "package:code_secure_flutter/rules/avoid_magic_numbers_rule.dart";
import "package:code_secure_flutter/rules/avoid_magic_strings_rule.dart";
import "package:code_secure_flutter/rules/avoid_nested_method_invocations_rule.dart";
import "package:code_secure_flutter/rules/avoid_nesting_rule.dart";
import "package:code_secure_flutter/rules/avoid_public_mutable_state_rule.dart";
import "package:code_secure_flutter/rules/avoid_recursion_rule.dart";
import "package:code_secure_flutter/rules/avoid_single_method_instance_field_rule.dart";
import "package:code_secure_flutter/rules/avoid_too_many_parameter_rule.dart";
import "package:code_secure_flutter/rules/avoid_unbound_loops_rule.dart";
import "package:code_secure_flutter/rules/avoid_unsafe_context_call_in_async_callbacks_rule.dart";
import "package:code_secure_flutter/rules/require_parameter_check_rule.dart";
import "package:code_secure_flutter/rules/require_return_value_check_rule.dart";
import "package:code_secure_flutter/rules/require_secure_credential_storage_rule.dart";
import "package:code_secure_flutter/rules/require_secure_random_number_generator_rule.dart";
import "package:code_secure_flutter/rules/require_secure_storage_for_sensitive_data_rule.dart";
import "package:code_secure_flutter/rules/require_stream_subscription_disposal_rule.dart";
import "package:code_secure_flutter/rules/require_verified_ssl_certificates_rule.dart";
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
      RequireReturnValueCheckRule(configs: configs),
      AvoidBooleanParametersRule(configs: configs),
      AvoidCommentedOutCodeRule(configs: configs),
      RequireSecureCredentialStorageRule(configs: configs),
      AvoidMagicNumbersRule(configs: configs),
      AvoidMagicStringsRule(configs: configs),
      AvoidPublicMutableStateRule(configs: configs),
      AvoidLargeClassesRule(configs: configs),
      RequireSecureRandomNumberGeneratorRule(configs: configs),
      RequireVerifiedSslCertificatesRule(configs: configs),
      AvoidNestedMethodInvocationsRule(configs: configs),
      AvoidLongAndComplexWidgetBuildMethodRule(configs: configs),
      AvoidUnboundLoopsRule(configs: configs),
      RequireParameterCheckRule(configs: configs),
      AvoidTooManyParameterRule(configs: configs),
      AvoidSingleMethodInstanceFieldRule(configs: configs),
      AvoidImpureBuildMethodsRule(configs: configs),
      AvoidUnsafeContextCallInAsyncCallbacksRule(configs: configs),
      RequireStreamSubscriptionDisposalRule(configs: configs),
      RequireSecureStorageForSensitiveDataRule(configs: configs),
    ];
  }
}
