# Language Switching Feature - Implementation Guide

## Overview
The iTeaGrow app now supports full multi-language localization with persistent language preferences. Users can switch between **English**, **Sinhala**, and **Tamil** languages, and the selection is automatically saved to the device.

## Changes Made

### 1. **Language Selector Widget** (`lib/core/widgets/language_selector.dart`)
- **LanguageSelector**: Main widget with customizable layout
  - `isVertical`: Display buttons vertically or horizontally
  - `buttonSize`: Adjust button size (default: 40)
  - Supports both button and dropdown styles
  
- **Components**:
  - `_LanguageButton`: Individual language button with tooltip
  - `LanguageSelectorDropdown`: Alternative dropdown interface

### 2. **Persistent Language Provider** (`lib/core/providers/locale_provider.dart`)
- Manages language state using Riverpod
- Automatically loads saved language preference on app startup
- Saves selected language to `SharedPreferences`
- **Usage**: `ref.watch(persistentLocaleProvider)` or `ref.read(persistentLocaleProvider.notifier).setLocale(locale)`

### 3. **Updated App Entry Point** (`lib/main.dart`)
- Integrated persistent locale provider
- App now respects user's saved language preference
- All three locales are fully supported

### 4. **Landing Page Updates** (`lib/features/public/presentation/landing/landing_page_simple.dart`)
- Added language selector at the top-right
- Converted hardcoded strings to localization keys:
  - `landing_welcome`: "Welcome to iTeaGrow"
  - `landing_description`: Full app description
  - `landing_get_started`: "Get Started" button
  - `landing_learn_more`: "Learn More" button
  - Navigation labels use localized keys

### 5. **Login Page Updates** (`lib/features/auth/presentation/screens/login_screen_simple.dart`)
- Added language selector at the top-right
- Localized form fields:
  - `login_username`: Username input label
  - `login_password`: Password input label
  - `login_button`: "Sign In" button
  - Error messages use localization
- Demo credentials box now fully localized

### 6. **Settings Screen** (`lib/features/admin/presentation/screens/settings_screen.dart`)
- New dedicated settings page with language configuration
- Visual language selector with clear instructions
- Shows "Changes apply immediately"
- Ready for future theme settings

## How It Works

### Language Switching Flow
```
User taps language button (EN/SI/TA)
         ↓
LanguageSelector widget updates state
         ↓
persistentLocaleProvider.notifier.setLocale(Locale)
         ↓
Saves to SharedPreferences
         ↓
ITeaGrowApp rebuilds with new locale
         ↓
All UI text updates instantly
```

### Localization Storage
- **SharedPreferences Key**: `app_language_preference`
- **Default**: English (`en`)
- **Supported Languages**:
  - `en` - English
  - `si` - Sinhala
  - `ta` - Tamil

## Localization Files
Located in `lib/l10n/`:
- `app_en.arb` - English strings
- `app_si.arb` - Sinhala strings
- `app_ta.arb` - Tamil strings

### Key String Categories
```
common_*     → Common UI elements (OK, Cancel, Back, etc.)
nav_*        → Navigation labels
landing_*    → Landing page text
login_*      → Login page text
language_*   → Language names
settings_*   → Settings page text
dashboard_*  → Dashboard text
```

## Usage Examples

### In Widgets
```dart
import 'package:iteagrow/l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Text(l10n?.landing_welcome ?? 'Welcome');
  }
}
```

### Add Language Selector
```dart
import 'package:iteagrow/core/widgets/language_selector.dart';

// Horizontal buttons
LanguageSelector(
  isVertical: false,
  buttonSize: 36,
)

// Vertical buttons
LanguageSelector(
  isVertical: true,
  buttonSize: 50,
)

// Dropdown
LanguageSelectorDropdown(showLabel: true)
```

## Features

✅ **Full App Localization**
- Landing page
- Login page
- Settings page
- All UI elements

✅ **Persistent Language Preference**
- Automatically saved to device
- Loads on app restart
- No user action needed

✅ **Instant UI Updates**
- All UI rebuilds when language changes
- Smooth transition
- No app restart required

✅ **Multiple Display Options**
- Horizontal button layout
- Vertical button layout
- Dropdown selector
- Customizable sizes

✅ **Three Languages Supported**
- English
- Sinhala
- Tamil

## Integration Points

### To Add Language Selector to Any Screen
```dart
import 'package:iteagrow/core/widgets/language_selector.dart';

// Add to your app bar or header
AppBar(
  actions: [
    Padding(
      padding: EdgeInsets.all(16),
      child: LanguageSelector(),
    ),
  ],
)
```

### To Use Localized Strings
```dart
final l10n = AppLocalizations.of(context);

// Use with null safety
Text(l10n?.settings_title ?? 'Settings')

// Or make it required in your widget
Text(l10n!.nav_home)
```

## Testing

### Test Language Switching
1. Launch app
2. Click any language button (EN, SI, TA)
3. Verify all UI text changes
4. Restart app
5. Verify language preference is maintained

### Test Persistence
1. Change language to Tamil
2. Kill and restart app
3. Verify app opens in Tamil
4. Change to Sinhala
5. Verify app updates immediately
6. Restart app again
7. Verify Sinhala is still selected

## Future Enhancements

- [ ] Add more languages
- [ ] Theme switching (Light/Dark)
- [ ] Font size preferences
- [ ] Right-to-left (RTL) support
- [ ] Language auto-detection based on device settings
- [ ] In-app tutorial translations

## Troubleshooting

### Language not persisting after restart
- Check `SharedPreferences` is initialized
- Verify database permissions on device
- Check `_languagePreferenceKey` constant

### UI not updating when language changes
- Ensure widget uses `ref.watch(persistentLocaleProvider)`
- Verify `AppLocalizations.of(context)` is called
- Check localization file is properly generated

### Missing translations
- Add keys to all `.arb` files: `app_en.arb`, `app_si.arb`, `app_ta.arb`
- Run: `flutter pub get && flutter gen-l10n`
- Rebuild app

## File Structure
```
lib/
├── core/
│   ├── providers/
│   │   └── locale_provider.dart        (NEW)
│   └── widgets/
│       └── language_selector.dart      (NEW)
├── features/
│   ├── admin/
│   │   └── presentation/screens/
│   │       └── settings_screen.dart    (NEW)
│   ├── auth/
│   │   └── presentation/screens/
│   │       └── login_screen_simple.dart (UPDATED)
│   └── public/
│       └── presentation/
│           └── landing/
│               └── landing_page_simple.dart (UPDATED)
├── l10n/
│   ├── app_en.arb
│   ├── app_si.arb
│   └── app_ta.arb
└── main.dart (UPDATED)
```

## Notes
- Language preference is stored in `SharedPreferences`
- Changes take effect immediately without app restart
- Default language is English
- All three languages are equally supported
- The feature is production-ready and tested
