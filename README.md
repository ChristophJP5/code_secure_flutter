# 🔒 Code Secure Flutter

<!-- [![Pub Version](https://img.shields.io/pub/v/code_secure_flutter.svg)](https://pub.dev/packages/code_secure_flutter) -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9D%A4-blue)](https://flutter.dev)



## About

**code_secure_flutter** is your friendly neighborhood security expert that never sleeps, doesn't drink coffee, and won't judge your code (out loud). 

This package provides a set of custom lint rules designed to enforce secure coding practices in Flutter applications. 

Because writing secure code is like flossing – I know i should do it, but without someone nagging me, ity probably won't happen consistently. 
The lint rules are that nagging voice, but for my (your) code.

**Developed with ❤️ and passion for good code by:** Christoph Polenz


## Installation 🚀

Add this package to your `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_lint: ^0.7.3 # or the latest version
  code_secure_flutter: 
    git:
      url: https://github.com/ChristophJP5/code_secure_flutter
      ref: main
```

Run:

```bash
flutter pub get
```

## Usage 🔧

* **Setup:** 
  * Create or update your `analysis_options.yaml` file in the root of your project:

    ```yaml
    # if you want to use a fixed version of the rules
    include: package:code_secure_flutter/analysis_options_1.0.0.yaml 
    # get the latest version of the rules
    include: package:code_secure_flutter/analysis_options.yaml 

    analyzer:
      plugins:
        - custom_lint
        
    # configure the custom lint rules
    custom_lint:
      rules:
        - avoid_long_and_complex_functions:
          error_severity: Warning
          function_max_char_count: 1100
        - avoid_nesting:
          error_severity: Warning
    ```
    Watch as your IDE lights up like a Christmas tree with all the possible issues you never knew you had! 🎄

* **Config:**
  * There are some configuration options available for each rule. Check the [example project](https://github.com/ChristophJP5/code_secure_flutter_example).
  * You can modify the severity of each rule in the `analysis_options.yaml` file. Just remember, "Warning" is like your mom saying "be careful" – it means you should probably listen.
    The following severities are available:
    - `ERROR`: This is a big deal. Fix it now or face the consequences.
    - `WARNING`: This is important, but you can probably fix it later. Or never. Your choice.
    - `INFO`: This is just a suggestion. Like your friend telling you to try pineapple on pizza. You can ignore it, but why would you?
    - `NONE`: This rule is not applied. It's like saying "I don't care" to your code. But deep down, we all know you do care.

## Custom Rules 

Our package comes with the following rules:

| Rule | Description | Severity |
|------|-------------|----------|
| [avoid_long_and_complex_functions](lib/rules/avoid_long_and_complex_functions_rule.dart) | Flags functions that are too long or complex. If your function needs its own zip code, it's too big. | WARNING |
| [avoid_long_and_complex_widget_build_method](lib/rules/avoid_long_and_complex_widget_build_method_rule.dart) | Keeps your widget's build methods simple. Remember, "build" is not French for "write a novel." | WARNING |
| [avoid_nesting](lib/rules/avoid_nesting_rule.dart) | Prevents excessive nesting. If your code looks like Russian dolls, you f*cked up. | WARNING |
| [avoid_recursion](lib/rules/avoid_recursion_rule.dart) | Flags recursive methods. | WARNING |
| [check_return_value](lib/rules/check_return_value_rule.dart) | Makes sure you don't ignore return values. They have feelings too. | ERROR |
| [loops_require_fixed_bound](lib/rules/loops_require_fixed_bound_rule.dart) | Ensures loops have a fixed bound to prevent infinite loops. | ERROR |
| [parameter_assert_required](lib/rules/parameter_assert_required_rule.dart) | Enforces parameter validation through assertions. Trust no one, not even your own parameters. | ERROR |
| [prefer_local_variable_for_single_method_instance_field](lib/rules/prefer_local_variable_for_single_method_instance_field_rule.dart) | Suggests using local variables when fields are only used in one method. Some things should be together, like me and my wife. | WARNING |
| [pure_build_methods](lib/rules/pure_build_methods_rule.dart) | Ensures build methods don't have side effects. If you still have Side effects, contact your doctor for counseling | ERROR |
| [require_mounted_check_in_async_callbacks](lib/rules/require_mounted_check_in_async_callbacks_rule.dart) | Requires mounted checks in async callbacks to prevent setState after dispose. Cause calling setState after dispose, is like calling your ex - technically possible but never a good idea. | ERROR |

## Configuration

For detailed configuration options, check out the [example project](https://github.com/ChristophJP5/code_secure_flutter_example).

## Contributing 🤝

Think i missed something? Found something that should be flagged? Have a rule idea that would make coding Flutter apps more secure?
**Feel free to create a Pull Request**

Just be aware that we maintain very high standards. Almost as high as Snoop Dogg.

## License 📄

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

