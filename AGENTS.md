# AGENTS.md - Agentic Coding Guidelines

This document provides guidelines for agents working on this Flutter codebase.

## Project Overview

- **Framework**: Flutter 3.x with Dart
- **State Management**: Riverpod (hooks_riverpod) + flutter_hooks
- **Routing**: go_router
- **Local Database**: Isar
- **HTTP Client**: Dio
- **Architecture**: Lightweight MVVM + Repository/Service separation

## Architecture Guidelines

All new feature development must follow the MVVM rules in
[`docs/mvvm_architecture.md`](docs/mvvm_architecture.md).

Project architecture is **lightweight MVVM + Repository/Service separation**:

- **View**: Flutter pages and widgets. Render UI and forward user events only.
- **ViewModel**: Riverpod Notifier/AsyncNotifier/StateNotifier or focused providers. Own page state and page workflows.
- **Repository**: Business API and persistence boundary. Convert responses into typed models.
- **Service / Manager**: Low-level infrastructure such as Dio, auth session, device info, and local database.
- **Model**: Data structures, JSON mapping, enum conversion, and light derived fields.

Strict rules:

- Views must not call Dio, `HttpDioManager`, `AuthSession`, or `IsarDB` directly.
- API paths must be declared in `HttpApi`.
- Nady network requests must use `HttpDioManager`.
- Do not introduce a second network stack.
- For any page with network requests, submit actions, or multiple loading/error states, create a ViewModel.

## Build / Lint / Test Commands

### Running the App
```bash
flutter run
```

### Running Tests
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Linting & Analysis
```bash
# Run static analysis
flutter analyze

# Fix automatically fixable issues
flutter analyze --fix
```

### Code Generation
```bash
# Generate Isar, Riverpod, and Retrofit code
dart run build_runner build --delete-conflicting-outputs
```

### Building
```bash
# Build iOS
flutter build ios

# Build iOS simulator
flutter build ios --simulator --no-codesign
```

## Code Style Guidelines

### General Principles
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use Flutter's recommended lints (package:flutter_lints)
- Keep files under 400 lines when possible
- Use meaningful names that convey intent

### Naming Conventions

**Classes, Enums, Typedefs:**
```dart
class DiaryEntry { }           // PascalCase
enum UserActionOption { }     // PascalCase
typedef ApiResponse = { };     // PascalCase
```

**Methods, Variables, Constants:**
```dart
void fetchUserData() { }      // camelCase
final userName = 'John';      // camelCase
const int maxRetries = 3;     // camelCase with k prefix for constants in some codebases
```

**Private Members:**
```dart
class _PrivateClass { }        // Leading underscore
final _cache = {};             // Leading underscore
void _handleError() { }        // Leading underscore
```

**File Names:**
```dart
diary_entry.dart               // snake_case
api_client.dart                // snake_case
home_page.dart                 // snake_case
```

### Import Organization

Organize imports in the following order (separate with blank lines):

1. Dart/Flutter SDK imports
2. Package imports (pub.dev packages)
3. Relative imports (project files)

```dart
// 1. Dart/Flutter SDK
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// 2. Package imports
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 3. Relative imports
import '../model/diary_entry.dart';
import '../manager/providers.dart';
```

### Types & Type Annotations

- Use type annotations on public API parameters and return types
- Prefer `final` over `var`
- Use `const` constructors when possible
- Enable strict type checking in analysis_options.yaml

```dart
// Good
final String userName = 'John';
const double pi = 3.14;
Widget build(BuildContext context) { ... }

// Avoid
var userName = 'John';
```

### Widgets

**Prefer StatelessWidget for pure UI:**
```dart
class ContentView extends StatelessWidget {
  final DiaryEntry entry;
  const ContentView({super.key, required this.entry});

  @override
  Widget build(BuildContext context) { ... }
}
```

**Use HookWidget or HookConsumerWidget for stateful logic:**
```dart
class _HomePageBody extends HookWidget {
  const _HomePageBody({super.key, required this.userInfoAsync});

  @override
  Widget build(BuildContext context) { ... }
}
```

**Use ConsumerWidget or HookConsumerWidget for Riverpod providers:**
```dart
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

### Error Handling

- Use try-catch for async operations
- Return meaningful error messages
- Handle DioException specifically for network errors

```dart
Future<ApiResponse> post(String path, {Map<String, dynamic>? data}) async {
  try {
    final response = await dio.post(path, data: data);
    // Handle response
    return ApiResponse(success: true, data: response.data);
  } on DioException catch (e) {
    return _handleDioException(e);
  } catch (e) {
    return ApiResponse(success: false, message: 'Unexpected error: $e');
  }
}
```

### Async/Await

- Always use async/await over raw Futures
- Handle loading and error states in UI

```dart
final diaryEntriesProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final isar = await IsarDB.instance.db;
  final entries = await isar.diaryEntrys.where().findAll();
  return entries;
});
```

### Collections

- Use collection literals when concise
- Prefer functional methods (map, where, fold) for transformations

```dart
final names = entries.map((e) => e.userNickname).toList();
final filtered = entries.where((e) => e.moodIndex != null).toList();
```

### Enums

```dart
enum UserActionOption {
  delete('Delete'),
  report('Report'),
  block('Block');

  final String label;
  const UserActionOption(this.label);
}
```

### Documentation

- Use `///` for public API documentation
- Add comments for complex business logic
- Include parameter descriptions for non-trivial methods

```dart
/// Fetches all diary entries from local database.
/// Returns sorted by date descending (most recent first).
Future<List<DiaryEntry>> fetchEntries() async { ... }
```

### Testing

- Place tests in the `test/` directory
- Use widget_test.dart pattern with WidgetTester
- Name test files to match: `home_page.dart` -> `home_page_test.dart`

```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
});
```

### UI Patterns

- Use `flutter_screenutil` for responsive sizing (designSize: Size(375, 812))
- Follow the existing color scheme (yellow primary: Color(0xFFF9E707))
- Use `MediaQuery.of(context).padding` for safe area handling

### Router Configuration

- Use go_router for declarative routing
- Define routes in `lib/configs/app_routers.dart`
- Use named routes for clarity

```dart
final GoRouter goRouter = GoRouter(
  initialLocation: '/launch',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
```

### Asset Management

- Place assets in `assets/` directory
- Define assets in pubspec.yaml under `flutter.assets`

```yaml
flutter:
  assets:
    - assets/base/
    - assets/tabbar/
```
