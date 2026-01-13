import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:iteagrow/core/providers/locale_provider.dart';

/// Language selector button that allows users to change the app language
/// Supports English, Sinhala, and Tamil
class LanguageSelector extends ConsumerWidget {
  final bool isVertical;
  final double buttonSize;

  const LanguageSelector({
    super.key,
    this.isVertical = false,
    this.buttonSize = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(persistentLocaleProvider);
    final localizations = AppLocalizations.of(context);

    if (localizations == null) {
      return const SizedBox.shrink();
    }

    final languages = [
      ('en', 'EN', localizations.language_english),
      ('si', 'SI', localizations.language_sinhala),
      ('ta', 'TA', localizations.language_tamil),
    ];

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: languages
            .map((lang) => _LanguageButton(
                  code: lang.$1,
                  label: lang.$2,
                  fullName: lang.$3,
                  isSelected: currentLocale.languageCode == lang.$1,
                  onPressed: () {
                    ref.read(persistentLocaleProvider.notifier).setLocale(Locale(lang.$1));
                  },
                  size: buttonSize,
                ))
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final isLast = entry.key == languages.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: entry.value,
          );
        }).toList(),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: languages
          .map((lang) => _LanguageButton(
                code: lang.$1,
                label: lang.$2,
                fullName: lang.$3,
                isSelected: currentLocale.languageCode == lang.$1,
                onPressed: () {
                  ref.read(persistentLocaleProvider.notifier).setLocale(Locale(lang.$1));
                },
                size: buttonSize,
              ))
          .toList()
          .asMap()
          .entries
          .map((entry) {
        final isLast = entry.key == languages.length - 1;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 8),
          child: entry.value,
        );
      }).toList(),
    );
  }
}

/// Individual language button
class _LanguageButton extends StatelessWidget {
  final String code;
  final String label;
  final String fullName;
  final bool isSelected;
  final VoidCallback onPressed;
  final double size;

  const _LanguageButton({
    required this.code,
    required this.label,
    required this.fullName,
    required this.isSelected,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: fullName,
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 4 : 1,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown-style language selector
class LanguageSelectorDropdown extends ConsumerWidget {
  final bool showLabel;

  const LanguageSelectorDropdown({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context);

    if (localizations == null) {
      return const SizedBox.shrink();
    }

    final languages = [
      MapEntry('en', localizations.language_english),
      MapEntry('si', localizations.language_sinhala),
      MapEntry('ta', localizations.language_tamil),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Icon(Icons.language, size: 20),
          const SizedBox(width: 8),
        ],
        DropdownButton<String>(
          value: currentLocale.languageCode,
          items: languages
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(localeProvider.notifier).state = Locale(value);
            }
          },
        ),
      ],
    );
  }
}
