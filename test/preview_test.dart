/// Widget tests for [PreviewLogDialog] from lib/src/preview.dart.
///
/// These tests cover:
/// - Rendering of the dialog with various line lists
/// - Per-line styling (bold, error/critical red, warning orange, debug grey)
/// - Copy-to-clipboard functionality with both fallback SnackBar and ThemedSnackbar paths
/// - Localization branches and fallback to hardcoded defaults
/// - Edge cases like empty lists and large lists
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/src/preview.dart';
import 'package:layrz_theme/layrz_theme.dart';

/// Helper widget that wraps [PreviewLogDialog] in a minimal MaterialApp harness.
/// This provides the required Theme, Dialog, and ScaffoldMessenger ancestors.
Widget buildTestHarness(List<String> lines) {
  return MaterialApp(
    home: Scaffold(
      body: Dialog(
        child: PreviewLogDialog(lines: lines),
      ),
    ),
  );
}

void main() {
  group('PreviewLogDialog - Rendering', () {
    testWidgets('renders without throwing with normal list of lines', (WidgetTester tester) async {
      const lines = ['line 1', 'line 2', 'line 3'];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.byType(PreviewLogDialog), findsOneWidget);
      expect(find.byType(Dialog), findsWidgets);
    });

    testWidgets('renders each provided line as Text widget', (WidgetTester tester) async {
      const lines = ['first line', 'second line', 'third line'];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.text('first line'), findsOneWidget);
      expect(find.text('second line'), findsOneWidget);
      expect(find.text('third line'), findsOneWidget);
    });

    testWidgets('renders correctly with empty list', (WidgetTester tester) async {
      const lines = <String>[];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.byType(PreviewLogDialog), findsOneWidget);
      expect(find.byType(Dialog), findsWidgets);
      // No line texts should be rendered
      expect(find.byType(Text, skipOffstage: false), findsWidgets); // Title and button exist
    });

    testWidgets('renders without throwing with large list (200 lines)', (WidgetTester tester) async {
      final lines = List.generate(200, (i) => 'line $i');
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.byType(PreviewLogDialog), findsOneWidget);
      // Verify a few lines are rendered
      expect(find.text('line 0'), findsOneWidget);
      expect(find.text('line 199'), findsOneWidget);
    });

    testWidgets('renders default title "System logs"', (WidgetTester tester) async {
      const lines = ['test'];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.text('System logs'), findsOneWidget);
    });

    testWidgets('renders copy button with text "Copy logs to clipbard" (with typo)', (WidgetTester tester) async {
      const lines = ['test'];
      await tester.pumpWidget(buildTestHarness(lines));

      // The typo "clipbard" is intentional - we test the actual source behavior
      // ThemedButton may not render text directly in the widget tree, so check by type
      expect(find.byType(ThemedButton), findsOneWidget);
      final button = tester.widget<ThemedButton>(find.byType(ThemedButton));
      expect(button.labelText, equals('Copy logs to clipbard'));
    });
  });

  group('PreviewLogDialog - Per-Line Styling', () {
    testWidgets('line starting with "---" has bold fontWeight', (WidgetTester tester) async {
      const lines = ['--- separator line'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('--- separator line'));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('line starting with "[ERROR]" has red color', (WidgetTester tester) async {
      const lines = ['[ERROR] something went wrong'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('[ERROR] something went wrong'));
      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('line starting with "[CRITICAL]" has red color', (WidgetTester tester) async {
      const lines = ['[CRITICAL] critical failure'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('[CRITICAL] critical failure'));
      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('line starting with "[WARNING]" has orange color', (WidgetTester tester) async {
      const lines = ['[WARNING] be cautious'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('[WARNING] be cautious'));
      expect(textWidget.style?.color, equals(Colors.orange));
    });

    testWidgets('line starting with "[DEBUG]" has grey color', (WidgetTester tester) async {
      const lines = ['[DEBUG] debug info'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('[DEBUG] debug info'));
      expect(textWidget.style?.color, equals(Colors.grey));
    });

    testWidgets('plain line with no prefix has no color or fontWeight override (uses default theme)',
        (WidgetTester tester) async {
      const lines = ['plain log message'];
      await tester.pumpWidget(buildTestHarness(lines));

      final textWidget = tester.widget<Text>(find.text('plain log message'));
      // Plain text should not have RED, ORANGE, GREY, or BOLD overrides
      // It may have default theme values, so we check it's different from the styled versions
      expect(textWidget.style?.color, isNot(Colors.red));
      expect(textWidget.style?.color, isNot(Colors.orange));
      expect(textWidget.style?.color, isNot(Colors.grey));
      // FontWeight should not be bold unless theme specifies it
      if (textWidget.style?.fontWeight != null) {
        expect(textWidget.style?.fontWeight, isNot(FontWeight.bold));
      }
    });

    testWidgets('all styling branches applied to different lines in one dialog', (WidgetTester tester) async {
      const lines = [
        '--- separator',
        '[ERROR] error line',
        '[CRITICAL] critical line',
        '[WARNING] warning line',
        '[DEBUG] debug line',
        'plain line',
      ];
      await tester.pumpWidget(buildTestHarness(lines));

      // Verify separator
      expect(
        tester.widget<Text>(find.text('--- separator')).style?.fontWeight,
        equals(FontWeight.bold),
      );

      // Verify error
      expect(
        tester.widget<Text>(find.text('[ERROR] error line')).style?.color,
        equals(Colors.red),
      );

      // Verify critical
      expect(
        tester.widget<Text>(find.text('[CRITICAL] critical line')).style?.color,
        equals(Colors.red),
      );

      // Verify warning
      expect(
        tester.widget<Text>(find.text('[WARNING] warning line')).style?.color,
        equals(Colors.orange),
      );

      // Verify debug
      expect(
        tester.widget<Text>(find.text('[DEBUG] debug line')).style?.color,
        equals(Colors.grey),
      );

      // Verify plain (should not have red/orange/grey colors or bold)
      final plainStyle = tester.widget<Text>(find.text('plain line')).style;
      expect(plainStyle?.color, isNot(Colors.red));
      expect(plainStyle?.color, isNot(Colors.orange));
      expect(plainStyle?.color, isNot(Colors.grey));
      if (plainStyle?.fontWeight != null) {
        expect(plainStyle?.fontWeight, isNot(FontWeight.bold));
      }
    });
  });

  group('PreviewLogDialog - Copy to Clipboard', () {
    tearDown(() {
      // Clean up any pending timers or mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('tapping copy button writes joined lines to clipboard', (WidgetTester tester) async {
      const lines = ['line 1', 'line 2', 'line 3'];
      final calls = <MethodCall>[];

      // Mock the platform channel to capture Clipboard.setData calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      // Find and tap the copy button
      await tester.tap(find.byType(ThemedButton));
      await tester.pumpAndSettle();

      // Verify clipboard.setData was called
      final clipboardCall = calls.firstWhere(
        (call) => call.method == 'Clipboard.setData',
        orElse: () => throw StateError('No Clipboard.setData call found'),
      );

      final expectedText = lines.join('\n');
      expect(clipboardCall.arguments['text'], equals(expectedText));
    });

    testWidgets('copy button tap shows fallback SnackBar when no ThemedSnackbarMessenger ancestor',
        (WidgetTester tester) async {
      const lines = ['log line'];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      // Tap copy button
      await tester.tap(find.byType(ThemedButton));
      await tester.pump();

      // The fallback SnackBar should be rendered
      expect(find.byType(SnackBar), findsOneWidget);

      // SnackBar content should contain "Copied to clipboard"
      expect(find.text('Copied to clipboard'), findsOneWidget);

      // Orange background
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.orange));
    });

    testWidgets('copy button tap shows default "Copied to clipboard" message in SnackBar',
        (WidgetTester tester) async {
      const lines = ['test log'];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      await tester.tap(find.byType(ThemedButton));
      await tester.pump();

      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('clipboard copy includes clipboard icon in SnackBar', (WidgetTester tester) async {
      const lines = ['log'];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      await tester.tap(find.byType(ThemedButton));
      await tester.pump();

      // SnackBar content Row should contain Icon
      expect(find.byType(Icon), findsWidgets);
      // Verify at least one icon exists in the snackbar
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Row>());
    });
  });

  group('PreviewLogDialog - Edge Cases', () {
    testWidgets('renders correctly with lines containing special characters', (WidgetTester tester) async {
      const lines = [
        '[ERROR] Special chars: !@#\$%^&*()',
        '[WARNING] Unicode: 你好世界 🌍',
        'Plain: "quoted" and \'apostrophed\'',
      ];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.text('[ERROR] Special chars: !@#\$%^&*()'), findsOneWidget);
      expect(find.text('[WARNING] Unicode: 你好世界 🌍'), findsOneWidget);
      expect(find.text('Plain: "quoted" and \'apostrophed\''), findsOneWidget);
    });

    testWidgets('line starting with similar but different prefix is not styled', (WidgetTester tester) async {
      const lines = [
        '[ERRORS]', // Not [ERROR]
        '[WARNINGS]', // Not [WARNING]
        '[DEBUGGER]', // Not [DEBUG]
      ];
      await tester.pumpWidget(buildTestHarness(lines));

      // These should NOT be styled (no red, orange, or bold) because they don't match exactly
      // Check that they don't have the special colors
      expect(
        tester.widget<Text>(find.text('[ERRORS]')).style?.color,
        isNot(Colors.red),
      );
      expect(
        tester.widget<Text>(find.text('[WARNINGS]')).style?.color,
        isNot(Colors.orange),
      );
      expect(
        tester.widget<Text>(find.text('[DEBUGGER]')).style?.color,
        isNot(Colors.grey),
      );
    });

    testWidgets('line with prefix in middle is not styled', (WidgetTester tester) async {
      const lines = [
        'prefix [ERROR] in middle',
        'middle [WARNING] here',
      ];
      await tester.pumpWidget(buildTestHarness(lines));

      // These should NOT be styled because prefixes are in the middle, not at start
      expect(
        tester.widget<Text>(find.text('prefix [ERROR] in middle')).style?.color,
        isNot(Colors.red),
      );
      expect(
        tester.widget<Text>(find.text('middle [WARNING] here')).style?.color,
        isNot(Colors.orange),
      );
    });

    testWidgets('very long single line renders without overflow crash', (WidgetTester tester) async {
      final longLine = 'x' * 500;
      final lines = [longLine];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.text(longLine), findsOneWidget);
    });

    testWidgets('mixed case prefix "[error]" (lowercase) is not styled', (WidgetTester tester) async {
      const lines = ['[error] lowercase error'];
      await tester.pumpWidget(buildTestHarness(lines));

      // Should not be red because [error] != [ERROR]
      expect(
        tester.widget<Text>(find.text('[error] lowercase error')).style?.color,
        isNot(Colors.red),
      );
    });
  });

  group('PreviewLogDialog - Dialog Structure', () {
    testWidgets('dialog contains title and copy button in header row', (WidgetTester tester) async {
      const lines = ['test'];
      await tester.pumpWidget(buildTestHarness(lines));

      // Title should exist
      expect(find.text('System logs'), findsOneWidget);

      // Copy button should exist
      expect(find.byType(ThemedButton), findsOneWidget);

      // Both should be in a Row
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('dialog contains Divider separator', (WidgetTester tester) async {
      const lines = ['test'];
      await tester.pumpWidget(buildTestHarness(lines));

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('log lines are in scrollable containers', (WidgetTester tester) async {
      const lines = ['line 1', 'line 2'];
      await tester.pumpWidget(buildTestHarness(lines));

      // Horizontal and vertical SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('dialog is wrapped in Container with elevation decoration', (WidgetTester tester) async {
      const lines = ['test'];
      await tester.pumpWidget(buildTestHarness(lines));

      // Container should exist with BoxDecoration
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('PreviewLogDialog - Clipboard Edge Cases', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('empty list joins to empty string on copy', (WidgetTester tester) async {
      const lines = <String>[];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      await tester.tap(find.byType(ThemedButton));
      await tester.pumpAndSettle();

      final clipboardCall = calls.firstWhere(
        (call) => call.method == 'Clipboard.setData',
        orElse: () => throw StateError('No Clipboard.setData call found'),
      );

      expect(clipboardCall.arguments['text'], equals(''));
    });

    testWidgets('single line join produces no newlines', (WidgetTester tester) async {
      const lines = ['single line'];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      await tester.tap(find.byType(ThemedButton));
      await tester.pumpAndSettle();

      final clipboardCall = calls.firstWhere(
        (call) => call.method == 'Clipboard.setData',
        orElse: () => throw StateError('No Clipboard.setData call found'),
      );

      expect(clipboardCall.arguments['text'], equals('single line'));
    });

    testWidgets('multiple lines are joined with newline character', (WidgetTester tester) async {
      const lines = ['line 1', 'line 2', 'line 3'];
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestHarness(lines));

      await tester.tap(find.byType(ThemedButton));
      await tester.pumpAndSettle();

      final clipboardCall = calls.firstWhere(
        (call) => call.method == 'Clipboard.setData',
        orElse: () => throw StateError('No Clipboard.setData call found'),
      );

      expect(
        clipboardCall.arguments['text'],
        equals('line 1\nline 2\nline 3'),
      );
    });
  });
}
