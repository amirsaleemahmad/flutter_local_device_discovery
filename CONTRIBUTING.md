# Contributing to flutter_local_device_discovery

Thank you for your interest in contributing to `flutter_local_device_discovery`! This document describes the process and guidelines for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Release Process](#release-process)
- [Reporting Issues](#reporting-issues)
- [License](#license)

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a new branch for your feature or bugfix
4. Make your changes
5. Push to your fork and submit a pull request

## Development Setup

### Prerequisites

- Flutter SDK (latest stable channel)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter extensions
- Xcode (for iOS/macOS development)
- Android SDK (for Android development)
- CMake and Visual Studio (for Windows development)

### Install Dependencies

```bash
flutter pub get
```

For the example app:

```bash
cd example
flutter pub get
```

### Run Tests

```bash
flutter test
```

### Run Analysis

```bash
flutter analyze
```

## Project Structure

This is a federated Flutter plugin with the following structure:

```
flutter_local_device_discovery/
├── lib/                                    # Main package (public API)
│   ├── flutter_local_device_discovery.dart # Barrel export file
│   └── src/
│       ├── discovery/                      # Discovery engine and API
│       ├── models/                         # Public data models
│       └── utils/                          # Utility classes
├── flutter_local_device_discovery_platform_interface/
│   └── lib/src/
│       ├── models/                         # Native serializable models
│       ├── platform_interface.dart         # Abstract platform interface
│       └── method_channel_impl.dart        # Method channel implementation
├── flutter_local_device_discovery_android/ # Android implementation (Kotlin)
├── flutter_local_device_discovery_darwin/  # iOS & macOS implementation (Swift)
├── flutter_local_device_discovery_windows/ # Windows implementation (C++)
├── example/                                # Example application
└── test/                                   # Unit tests
```

## Coding Standards

### Dart

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for formatting
- Keep public API documented with dartdoc comments (`///`)
- Prefer composition over inheritance
- Use sealed classes for closed type hierarchies
- Use `const` constructors where possible
- Avoid dynamic types; prefer strong typing

### Kotlin (Android)

- Follow the [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use Android listener APIs without blocking the platform thread
- Keep platform code minimal; push logic to Dart where possible

### Swift (iOS/macOS)

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use async/await for async operations
- Use `NWBrowser` and `NWConnection` from the Network framework

### C++ (Windows)

- Use modern C++ (C++17 or later)
- Use `std::` namespace explicitly
- Keep platform code minimal

## Testing

### Writing Tests

- Write unit tests for all new public API
- Test edge cases and error conditions
- Use descriptive test names
- Group related tests using `group()`

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/flutter_local_device_discovery_test.dart
```

### Before Submitting

Ensure the following pass:

```bash
flutter analyze
flutter test
```

## Pull Request Process

1. **Create a branch** from `main` with a descriptive name:
   - `feature/add-ssdp-support`
   - `fix/ios-bonjour-crash`
   - `docs/update-readme`

2. **Make your changes** following the coding standards above

3. **Write or update tests** for your changes

4. **Update documentation** if needed (README, CHANGELOG, dartdoc comments)

5. **Run analysis and tests**:
   ```bash
   flutter analyze
   flutter test
   ```

6. **Update the CHANGELOG** under an "Unreleased" section:
   ```markdown
   ## Unreleased
   
   * Added support for SSDP search targets.
   * Fixed a crash on iOS when the local network permission is denied.
   ```

7. **Commit your changes** using conventional commit messages (see below)

8. **Push to your fork** and create a pull request

9. **Respond to review feedback** promptly and respectfully

### Pull Request Checklist

- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Code is commented, particularly in hard-to-understand areas
- [ ] Corresponding changes to documentation made
- [ ] Tests added for new functionality
- [ ] All tests pass
- [ ] `flutter analyze` passes with no issues
- [ ] CHANGELOG updated

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

### Examples

```
feat(android): add NSD service registration support
fix(ios): handle local network permission denial gracefully
docs(readme): add Windows platform configuration section
test(models): add tests for InternetAddressValue parsing
```

## Release Process

This repository contains five independently published packages. Keep their versions and hosted dependency constraints aligned before a release. Local path dependencies belong in `pubspec_overrides.yaml`; those files are excluded from the published archives.

Before publishing:

1. Update every package changelog and version.
2. Run `flutter analyze` and `flutter test` from the repository root.
3. Run `dart pub publish --dry-run` from each publishable package directory.
4. Commit the complete release so Pub validates a clean Git state.

Publish federated releases in dependency order, waiting for each stage to become available on pub.dev before continuing:

1. `flutter_local_device_discovery_platform_interface`
2. `flutter_local_device_discovery_android`
3. `flutter_local_device_discovery_darwin`
4. `flutter_local_device_discovery_windows`
5. `flutter_local_device_discovery`

Publishing is irreversible. Review the archive file list shown by each dry run before confirming the upload.

## Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Check the documentation** (README, API docs)
3. **Try the example app** to reproduce the issue

When creating an issue, include:

- **Description**: Clear description of the problem
- **Steps to reproduce**: Minimal reproduction steps
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Environment**:
  - Flutter version (`flutter --version`)
  - Dart version (`dart --version`)
  - Platform(s) affected (Android, iOS, macOS, Windows)
  - Device/emulator model and OS version
- **Logs**: Relevant error messages or stack traces
- **Code sample**: Minimal code that reproduces the issue

## Feature Requests

We welcome feature requests! Please:

1. Check if the feature has already been requested
2. Describe the use case clearly
3. Explain why existing functionality doesn't meet your needs
4. Suggest an API design if possible

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible new functionality
- **PATCH**: Backward-compatible bug fixes

## License

By contributing, you agree that your contributions will be licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Questions?

Feel free to reach out by:
- Opening a GitHub issue
- Emailing the maintainer at amirsaleemahmad@gmail.com

Thank you for contributing!
