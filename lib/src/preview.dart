import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PreviewLogDialog extends StatelessWidget {
  final List<String> lines;
  const PreviewLogDialog({
    super.key,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    LayrzAppLocalizations? i18n = LayrzAppLocalizations.maybeOf(context);
    String titleText;
    String copyText;
    String copiedToClipboardText;

    if (i18n != null) {
      if (i18n.hasTranslation('logs.title')) {
        titleText = i18n.t('logs.title');
      } else {
        titleText = 'System logs';
      }
      if (i18n.hasTranslation('logs.copy.clipboard')) {
        copyText = i18n.t('logs.copy.clipboard');
      } else {
        copyText = 'Copy logs to clipbard';
      }
      if (i18n.hasTranslation('logs.copy.success')) {
        copiedToClipboardText = i18n.t('logs.copy.success');
      } else {
        copiedToClipboardText = 'Copied to clipboard';
      }
    } else {
      titleText = 'System logs';
      copyText = 'Copy logs to clipbard';
      copiedToClipboardText = 'Copied to clipboard';
    }
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: generateContainerElevation(context: context, elevation: 5),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                ThemedButton(
                  labelText: copyText,
                  color: Colors.orange,
                  icon: MdiIcons.contentCopy,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                    if (!context.mounted) return;

                    if (ThemedSnackbarMessenger.maybeOf(context) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(MdiIcons.contentCopy, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  copiedToClipboardText,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: copiedToClipboardText,
                        icon: MdiIcons.contentCopy,
                        color: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: lines.map((line) {
                      TextStyle? style = Theme.of(context).textTheme.bodySmall;
                      if (line.startsWith('---')) {
                        style = style?.copyWith(fontWeight: FontWeight.bold);
                      } else if (line.startsWith('[ERROR]') || line.startsWith('[CRITICAL]')) {
                        style = style?.copyWith(color: Colors.red);
                      } else if (line.startsWith('[WARNING]')) {
                        style = style?.copyWith(color: Colors.orange);
                      } else if (line.startsWith('[DEBUG]')) {
                        style = style?.copyWith(color: Colors.grey);
                      }

                      return Text(
                        line,
                        style: style,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
