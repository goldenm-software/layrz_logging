# layrz_logging

[![Pub version](https://img.shields.io/pub/v/layrz_logging?logo=flutter)](https://pub.dev/packages/layrz_logging)
[![popularity](https://img.shields.io/pub/popularity/layrz_logging?logo=flutter)](https://pub.dev/packages/layrz_logging/score)
[![likes](https://img.shields.io/pub/likes/layrz_logging?logo=flutter)](https://pub.dev/packages/layrz_logging/score)
[![GitHub license](https://img.shields.io/github/license/goldenm-software/layrz_logging?logo=github)](https://github.com/goldenm-software/layrz_logging)

Managing errors and logs can be a pain, but with `layrz_logging` you can easily manage your logs and errors in your Flutter applications.
Supports all of the platforms that Flutter supports.

## Usage
To use this plugin, add `layrz_logging` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

```yaml
dependencies:
  flutter:
    sdk: flutter
  layrz_logging: ^latest_version
```

Then you can import the package in your Dart code:

```dart
import 'package:layrz_logging/layrz_logging.dart';

/// on your void main() function
void main() {
  WidgetsBindingInstance.ensureInitialized();
  Log.ensureInitialized(); // Be careful, this method should be invoked after `WidgetsBindingInstance.ensureInitialized()`

  runApp(MyApp());
}

/// And, wherever you want to log something
Log.debug("Hello, World!"); // Debug error level
Log.info("Hello, World!"); // Info error level
Log.warning("Hello, World!"); // Warning error level
Log.error("Hello, World!"); // Error error level
Log.fatal("Hello, World!"); // Fatal error level

/// Also, Log is capable to handle all flutter or platform-specific errors without doing anything

/// You can also get the logs
///
/// On native platforms (Android, iOS, macOS, Windows, Linux) the logs are saved in a file
/// On web platform, the logs are stored on an `List`, and limited to 100 records
List<String> logs = await Log.fetchLogs();

/// If you upgraded from v1.1 or below, the LayrzLogging class is still exists, but on backward compatibility mode
LayrzLogging.debug("Hello, World!"); // Debug error level
LayrzLogging.info("Hello, World!"); // Info error level
LayrzLogging.warning("Hello, World!"); // Warning error level
LayrzLogging.error("Hello, World!"); // Error error level
LayrzLogging.fatal("Hello, World!"); // Fatal error level
```

## FAQ

### Why is this package called `layrz_logging`?
All packages developed by [Layrz](https://layrz.com) are prefixed with `layrz_`, check out our other packages on [pub.dev](https://pub.dev/publishers/goldenm.com/packages).

### I need to pay to use this package?
<b>No!</b> This library is free and open source, you can use it in your projects without any cost, but if you want to support us, give us a thumbs up here in [pub.dev](https://pub.dev/packages/layrz_logging) and star our [Repository](https://github.com/goldenm-software/layrz_logging)!

### Can I contribute to this package?
<b>Yes!</b> We are open to contributions, feel free to open a pull request or an issue on the [Repository](https://github.com/goldenm-software/layrz_logging)!

### I have a question, how can I contact you?
If you need more assistance, you open an issue on the [Repository](https://github.com/goldenm-software/layrz_logging) and we're happy to help you :)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This project is maintained by [Golden M](https://goldenm.com) with authorization of [Layrz LTD](https://layrz.com).

## Who are you? / Want to work with us?
<b>Golden M</b> is a software and hardware development company what is working on a new, innovative and disruptive technologies. For more information, contact us at [sales@goldenm.com](mailto:sales@goldenm.com) or via WhatsApp at [+(507)-6979-3073](https://wa.me/50769793073?text="From%20layrz_logging%20flutter%20library.%20Hello").
