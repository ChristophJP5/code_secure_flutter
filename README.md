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
| [require_return_value_check](lib/rules/require_return_value_check_rule.dart) | Makes sure you don't ignore return values. They have feelings too. | ERROR |
| [avoid_unbound_loops](lib/rules/avoid_unbound_loops_rule.dart) | Ensures loops have a fixed bound to prevent infinite loops. | ERROR |
| [require_parameter_check](lib/rules/require_parameter_check_rule.dart) | Enforces parameter validation through assertions. Trust no one, not even your own parameters. | ERROR |
| [avoid_boolean_parameters](lib/rules/avoid_boolean_parameters_rule.dart) | Forces you to explain boolean parameters so future-you remembers what `true` meant. | WARNING |
| [avoid_commented_out_code](lib/rules/avoid_commented_out_code_rule.dart) | Shames giant commented blobs so you delete them instead of hoarding legacy junk. | WARNING |
| [avoid_magic_numbers](lib/rules/avoid_magic_numbers_rule.dart) | Forces you to give scary numbers a friendly, well-named constant. | WARNING |
| [avoid_magic_strings](lib/rules/avoid_magic_strings_rule.dart) | Nudges you to name repeated strings instead of sprinkling literals everywhere. | WARNING |
| [avoid_nested_method_invocations](lib/rules/avoid_nested_method_invocations_rule.dart) | Stops excessively long method chains so you can actually step through them in a debugger. | WARNING |
| [require_stream_subscription_disposal](lib/rules/require_stream_subscription_disposal_rule.dart) | Forces every StreamSubscription to get a proper `cancel()` in `dispose()`. No more zombie listeners. | ERROR |
| [avoid_too_many_parameters](lib/rules/avoid_too_many_parameters_rule.dart) | Shames APIs with endless parameters so you reach for data classes or builders instead. | WARNING |
| [require_secure_credential_storage](lib/rules/require_secure_credential_storage_rule.dart) | Catches inline secrets before they end up immortalized in git history. | ERROR |
| [require_secure_storage_for_sensitive_data](lib/rules/require_secure_storage_for_sensitive_data_rule.dart) | Yells when you try to stash tokens in SharedPreferences instead of the platform keystore. | ERROR |
| [require_secure_random_number_generator](lib/rules/require_secure_random_number_generator_rule.dart) | Warns when `Random()` is used for anything more serious than shuffling a deck. | ERROR |
| [avoid_public_mutable_state](lib/rules/avoid_public_mutable_state_rule.dart) | Reminds you that public mutable fields are just global variables in disguise. | WARNING |
| [avoid_large_classes](lib/rules/avoid_large_classes_rule.dart) | Points out god classes before they become religions. | WARNING |
| [require_verified_ssl_certificates](lib/rules/require_verified_ssl_certificates_rule.dart) | Prevents code from blindly trusting every TLS certificate on the internet. | ERROR |
| [avoid_single_method_instance_field](lib/rules/avoid_single_method_instance_field_rule.dart) | Suggests using local variables when fields are only used in one method. Some things should be together, like me and my wife. | WARNING |
| [avoid_impure_build_methods](lib/rules/avoid_impure_build_methods_rule.dart) | Ensures build methods don't have side effects. If you still have Side effects, contact your doctor for counseling | ERROR |
| [avoid_unsafe_context_call_in_async_callbacks](lib/rules/avoid_unsafe_context_call_in_async_callbacks_rule.dart) | Requires mounted checks in async callbacks to prevent setState after dispose. Cause calling setState after dispose, is like calling your ex - technically possible but never a good idea. | ERROR |


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

#### require_return_value_check

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_return_value_check:
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

#### avoid_unbound_loops

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_unbound_loops:
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

#### require_parameter_check

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_parameter_check:
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
    : assert(username.length > 0, 'Username cannot be empty'),
      assert(age > 0, 'Age must be positive');
  
  @override
  Widget build(BuildContext context) {
    return Text('$username: $age');
  }
}
```

#### avoid_boolean_parameters

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_boolean_parameters:
        min_comment_length: 12
```

**BAD:**
```dart
Future<void> updateUser(bool force) async {
  // Nobody remembers what `force` does.
}
```

**GOOD:**
```dart
Future<void> updateUser(
  bool force, // Forces remote refresh even if cache looks valid.
) async {
  // Clear explanation = happy reviewers.
}
```

#### avoid_commented_out_code

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_commented_out_code:
        min_consecutive_lines: 3
        min_detection_score: 2
```

**BAD:**
```dart
// Future<void> legacyFlow() async {
//   await api.fetch();
//   if (!mounted) return;
//   setState(() {});
// }
```

**GOOD:**
```dart
// Document the follow-up instead of freezing code in amber.
// TODO(BUG-123): Reintroduce new flow once backend is fixed.
```

#### avoid_nested_method_invocations

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_nested_method_invocations:
        max_chain_depth: 4
```

**BAD:**
```dart
final response = client
    .tenant(id)
    .account(userId)
    .withHeaders(headers)
    .withRetryPolicy(policy)
    .load()
    .map(transform)
    .where(filter)
    .single;
```

**GOOD:**
```dart
final tenant = client.tenant(id);
final account = tenant.account(userId);
final prepared = account.withHeaders(headers).withRetryPolicy(policy);
final response = await prepared.load();
final result = response.map(transform).where(filter).single;
```

#### require_stream_subscription_disposal

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_stream_subscription_disposal:
        require_dispose_override: true
```

**BAD:**
```dart
class FeedState extends State<FeedScreen> {
  late final StreamSubscription<Post> _postUpdates;

  @override
  void initState() {
    super.initState();
    _postUpdates = widget.stream.listen(_handlePost);
  }
  // Oops, no dispose/cancel.
}
```

#### avoid_too_many_parameters

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_too_many_parameters:
        max_parameter_count: 5
        ignore_override_methods: true
```

**BAD:**
```dart
Widget buildButton(
  String label,
  VoidCallback onTap,
  Color background,
  Color foreground,
  double width,
  double height,
  bool isLoading,
  IconData? icon,
) {
  // ...
}
```

#### require_secure_credential_storage

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_secure_credential_storage:
        min_literal_length: 8
        suspicious_keywords:
          - password
          - token
```

**BAD:**
```dart
const apiKey = "sk_live_51LsSomeMegaSecret";
final headers = {
  "Authorization": "Bearer ya29.a0AR...",
  "password": "hunter2",
};
```

**GOOD:**
```dart
final apiKey = dotenv.env["PAYMENTS_SECRET"]!;
final headers = {
  "Authorization": "Bearer ${tokenProvider()}"
};
```

#### require_secure_storage_for_sensitive_data

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_secure_storage_for_sensitive_data:
        sensitive_keys:
          - password
          - token
```

**BAD:**
```dart
await prefs.setString("refreshToken", token);
await prefs.setString("password", controller.text);
```

**GOOD:**
```dart
final secureStorage = const FlutterSecureStorage();
await secureStorage.write(key: "refreshToken", value: token);
```

#### require_secure_random_number_generator

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_secure_random_number_generator:
        ignored_identifiers: []
```

**BAD:**
```dart
final otp = Random().nextInt(999999);
final salt = Random().nextBytes(16);
```

**GOOD:**
```dart
final otp = Random.secure().nextInt(999999);
final salt = _secureRandomBytes(16); // from crypto package or platform API
```

#### require_verified_ssl_certificates

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - require_verified_ssl_certificates: {}
```

**BAD:**
```dart
client.badCertificateCallback = (cert, host, port) => true;
```

**GOOD:**
```dart
client.badCertificateCallback = (cert, host, port) {
  final isTrusted = allowedFingerprints.contains(cert.sha256);
  return isTrusted;
};
```


#### avoid_magic_numbers

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_magic_numbers:
        allowed_numbers:
          - "-1"
          - "0"
          - "0.5"
          - "1"
          - "2"
          - "10"
        ignore_const_contexts: true
```

**BAD:**
```dart
final throttle = 37;
if (millisecondsSinceLastTap < 250) {
  return;
}
```

**GOOD:**
```dart
const _throttleMs = 37;
const _cooldownMs = 250;

if (millisecondsSinceLastTap < _cooldownMs) {
  return;
}
await Future<void>.delayed(Duration(milliseconds: _throttleMs));
```

#### avoid_magic_strings

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_magic_strings:
        allowed_strings:
          - ""
          - " "
          - "."
        min_length: 3
        ignore_annotation_arguments: true
```

**BAD:**
```dart
if (status == "approved") {
  showToast("approved");
}
```

**GOOD:**
```dart
const statusApproved = "approved";

if (status == statusApproved) {
  showToast(statusApproved);
}
```

#### avoid_public_mutable_state

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_public_mutable_state:
        ignored_fields: []
        ignored_types:
          - valuenotifier
        ignored_classes: []
```

**BAD:**
```dart
class SessionController {
  String userId = ""; // Anybody can reassign this.
}
```

**GOOD:**
```dart
class SessionController {
  SessionController(this._userId);
  final String _userId;

  String get userId => _userId;
}
```

#### avoid_large_classes

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_large_classes:
        max_members: 20
        max_lines: 200
```

**BAD:**
```dart
class OrderService {
  // 400 lines of networking, validation, UI glue, everything.
}
```

**GOOD:**
```dart
class OrderRepository { /* networking */ }
class OrderValidator { /* validation */ }
class OrderPresenter { /* presentation */ }
```
**GOOD:**
```dart
class ButtonStyle {
  const ButtonStyle({
    required this.background,
    required this.foreground,
    required this.dimensions,
    this.icon,
  });

  final Color background;
  final Color foreground;
  final Size dimensions;
  final IconData? icon;
}

Widget buildButton({
  required String label,
  required VoidCallback onTap,
  required ButtonStyle style,
  bool isLoading = false,
}) {
  // Cleaner signature.
}
```

**GOOD:**
```dart
class FeedState extends State<FeedScreen> {
  late final StreamSubscription<Post> _postUpdates;

  @override
  void initState() {
    super.initState();
    _postUpdates = widget.stream.listen(_handlePost);
  }

  @override
  void dispose() {
    _postUpdates.cancel();
    super.dispose();
  }
}
```

#### avoid_single_method_instance_field

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_single_method_instance_field:
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

#### avoid_impure_build_methods

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_impure_build_methods:
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

#### avoid_unsafe_context_call_in_async_callbacks

**Configuration in `analysis_options.yaml`:**
```yaml
custom_lint:
  rules:
    - avoid_unsafe_context_call_in_async_callbacks:
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

