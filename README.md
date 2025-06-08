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

## Contributing 🤝

Think i missed something? Found something that should be flagged? Have a rule idea that would make coding Flutter apps more secure?
**Feel free to create a Pull Request**

## Custom Rules 

### Overview
My package comes with the following rules:

| Rule | Description | Severity |
|------|-------------|----------|
| [avoid_long_and_complex_functions](lib/rules/avoid_long_and_complex_functions_rule.dart) | Flags functions that are too long or complex. If your function needs its own zip code, it's too big. | WARNING |
| [avoid_long_and_complex_widget_build_method](lib/rules/avoid_long_and_complex_widget_build_method_rule.dart) | Keeps your widget's build methods simple. Remember, "build" is not French for "write a novel." | WARNING |
| [avoid_nesting](lib/rules/avoid_nesting_rule.dart) | Prevents excessive nesting. If your code looks like Russian dolls, you f*cked up. | WARNING |
| [avoid_recursion](lib/rules/avoid_recursion_rule.dart) | Flags recursive methods. | WARNING |
| [check_return_value](lib/rules/check_return_value_rule.dart) | Makes sure you don't ignore return values. They have feelings too. | ERROR |
| [loops_require_fixed_bound](lib/rules/loops_require_fixed_bound_rule.dart) | Ensures loops have a fixed bound to prevent infinite loops. | ERROR |
| [require_parameter_assert](lib/rules/require_parameter_assert_rule.dart) | Enforces parameter validation through assertions. Trust no one, not even your own parameters. | ERROR |
| [prefer_local_variable_for_single_method_instance_field](lib/rules/prefer_local_variable_for_single_method_instance_field_rule.dart) | Suggests using local variables when fields are only used in one method. Some things should be together, like me and my wife. | WARNING |
| [pure_build_methods](lib/rules/pure_build_methods_rule.dart) | Ensures build methods don't have side effects. If you still have Side effects, contact your doctor for counseling | ERROR |
| [require_mounted_check_in_async_callbacks](lib/rules/require_mounted_check_in_async_callbacks_rule.dart) | Requires mounted checks in async callbacks to prevent setState after dispose. Cause calling setState after dispose, is like calling your ex - technically possible but never a good idea. | ERROR |


### Configuration And Examples for Rules

<details>
<summary>avoid_long_and_complex_functions</summary>

**Configuration in
custom_lint:
  rules:
    - avoid_long_and_complex_functions:
        error_severity: Warning
        function_max_char_count: 1100
```

**BAD:**
```dart
void doEverythingAtOnce() {
  // 100+ lines of code with multiple responsibilities
  // Complex nested logic
  // Multiple different operations
  // ...
  // ...
}
```

**GOOD:**
```dart
void validateInput() {
  // 10-15 lines focused on input validation
}

void processData() {
  // 30 - 50 lines focused on data processing
}

void saveResults() {
  // 10-30 lines focused on saving results
}
```

#### avoid_long_and_complex_widget_build_method

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_long_and_complex_widget_build_method:
        error_severity: Warning
        build_method_max_char_count: 800
```

**BAD:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('My Screen'),
      // Many widgets and complex logic in one method
      // ...
      // ...
    ),
    body: Column(
      children: [
        // Dozens of widgets with complex conditionals
        // ...
        // ...
      ],
    ),
  );
}
```

**GOOD:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
  );
}

Widget _buildAppBar() {
  return AppBar(title: Text('My Screen'));
}

Widget _buildBody() {
  return Column(
    children: [
      _buildHeader(),
      _buildContent(),
      _buildFooter(),
    ],
  );
}
```

#### avoid_nesting

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_nesting:
        error_severity: Warning
        max_nesting_level: 3
```

**BAD:**
```dart
void processData(List<int> items) {
  if (items.isNotEmpty) {
    for (var item in items) {
      if (item > 0) {
        if (item % 2 == 0) {
          if (item < 100) {
            // Too many nesting levels
          }
        }
      }
    }
  }
}
```

**GOOD:**
```dart
void processData(List<int> items) {
  if (items.isEmpty) {
    return;
  }
  for (var item in items) {
    if (item <= 0) {
      continue; // Skip non-positive items
    }
    if (item >= 100) {
      continue; // limit processing to items less than 100
    }
    if (item.isEven) {
      
    }
  }
}
```

#### avoid_recursion

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_recursion:
        error_severity: Warning
```

**BAD:**
```dart
int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1); // Recursive call
}
```

**GOOD:**
```dart
int factorial(int n) {
  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}
```

#### check_return_value

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - check_return_value:
        error_severity: Error
```

**BAD:**
```dart
void processFile() {
  final content = file.readAsString(); // Return value ignored
  doSomethingElse(content);
}
```

**GOOD:**
```dart
Future<void> processFile() async {
  final content = await file.readAsString();
  if (content.isEmpty) {
    throw Exception('File is empty');
  }
  doSomethingElse();
}
```

#### loops_require_fixed_bound

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - loops_require_fixed_bound:
        error_severity: Error
```

**BAD:**
```dart
void infiniteLoop() {
  while (true) {
    // This could run forever
    doSomething();
  }
}
```

**GOOD:**
```dart
void boundedLoop() {
  final maxIterations = 100;
  int i = 0;
  
  while (i < maxIterations && !isDone()) {
    doSomething();
    i++;
  }
}
```

#### require_parameter_assert

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_parameter_assert:
        error_severity: Error
```

**BAD:**
```dart
class UserWidget extends StatelessWidget {
  final String username;
  final int age;
  
  const UserWidget({required this.username, required this.age});
  
  @override
  Widget build(BuildContext context) {
    // No parameter validation
    return Text('$username: $age');
  }
}
```

**GOOD:**
```dart
class UserWidget extends StatelessWidget {
  final String username;
  final int age;
  
  const UserWidget({required this.username, required this.age})
    : assert(username.isNotEmpty, 'Username cannot be empty'),
      assert(age > 0, 'Age must be positive');
  
  @override
  Widget build(BuildContext context) {
    return Text('$username: $age');
  }
}
```

#### prefer_local_variable_for_single_method_instance_field

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - prefer_local_variable_for_single_method_instance_field:
        error_severity: Warning
```

**BAD:**
```dart
class ProfileScreen extends StatelessWidget {
  final String _formattedDate = DateFormat.yMd().format(DateTime.now());
  
  @override
  Widget build(BuildContext context) {
    // _formattedDate only used here
    return Text('Date: $_formattedDate');
  }
}
```

**GOOD:**
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat.yMd().format(now);
    return Text('Date: $formattedDate');
  }
}
```

#### pure_build_methods

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - pure_build_methods:
        error_severity: Error
```

**BAD:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    analytics.logScreenView(name: 'MyWidget'); // Side effect
    return Text('Hello World');
  }
}
```

**GOOD:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello World');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    analytics.logScreenView(name: 'MyWidget');
  }
}
```

#### require_mounted_check_in_async_callbacks

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_mounted_check_in_async_callbacks:
        error_severity: Error
```

**BAD:**
```dart
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      setState(() { // No mounted check before setState
        isLoaded = true;
      });
    });
  }
}
```

**GOOD:**
```dart
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      if (!mounted) { 
        return;
      }
      setState(() {
        isLoaded = true;
      });
    });
  }
}
```


Just be aware that i maintain very high standards. Almost as high as Snoop Dogg.

## License 📄

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

