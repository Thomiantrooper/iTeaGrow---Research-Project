import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'iTeaGrow'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'AI-IoT Tea Monitoring System'**
  String get appTagline;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// No description provided for @nav_leaf_maturity.
  ///
  /// In en, this message translates to:
  /// **'Leaf Maturity'**
  String get nav_leaf_maturity;

  /// No description provided for @nav_disease.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get nav_disease;

  /// No description provided for @nav_fertilization.
  ///
  /// In en, this message translates to:
  /// **'Fertilization'**
  String get nav_fertilization;

  /// No description provided for @nav_powder_grading.
  ///
  /// In en, this message translates to:
  /// **'Powder Grading'**
  String get nav_powder_grading;

  /// No description provided for @nav_iot.
  ///
  /// In en, this message translates to:
  /// **'IoT Devices'**
  String get nav_iot;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @nav_about.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get nav_about;

  /// No description provided for @nav_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get nav_contact;

  /// No description provided for @landing_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to iTeaGrow'**
  String get landing_welcome;

  /// No description provided for @landing_description.
  ///
  /// In en, this message translates to:
  /// **'AI-powered IoT system for tea leaf monitoring, fertilization management, and powder grading'**
  String get landing_description;

  /// No description provided for @landing_get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get landing_get_started;

  /// No description provided for @landing_learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get landing_learn_more;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About iTeaGrow'**
  String get about_title;

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'iTeaGrow is a research project focused on developing an AI-IoT decision support system for tea cultivation in Sri Lanka. The system combines machine learning, IoT sensors, and mobile technology to help farmers optimize tea leaf quality, fertilization, and market value.'**
  String get about_description;

  /// No description provided for @about_features.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get about_features;

  /// No description provided for @about_feature_1.
  ///
  /// In en, this message translates to:
  /// **'AI-powered leaf maturity detection'**
  String get about_feature_1;

  /// No description provided for @about_feature_2.
  ///
  /// In en, this message translates to:
  /// **'Real-time IoT sensor monitoring'**
  String get about_feature_2;

  /// No description provided for @about_feature_3.
  ///
  /// In en, this message translates to:
  /// **'Disease detection and prevention'**
  String get about_feature_3;

  /// No description provided for @about_feature_4.
  ///
  /// In en, this message translates to:
  /// **'Smart fertilization recommendations'**
  String get about_feature_4;

  /// No description provided for @about_feature_5.
  ///
  /// In en, this message translates to:
  /// **'Tea powder quality grading'**
  String get about_feature_5;

  /// No description provided for @contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contact_title;

  /// No description provided for @contact_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contact_email;

  /// No description provided for @contact_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contact_phone;

  /// No description provided for @contact_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get contact_address;

  /// No description provided for @contact_feedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get contact_feedback;

  /// No description provided for @contact_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contact_message;

  /// No description provided for @contact_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contact_send;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_title;

  /// No description provided for @login_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get login_username;

  /// No description provided for @login_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_button;

  /// No description provided for @login_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get login_language;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get login_error;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @language_sinhala.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get language_sinhala;

  /// No description provided for @language_tamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get language_tamil;

  /// No description provided for @role_farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get role_farmer;

  /// No description provided for @role_manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get role_manager;

  /// No description provided for @role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get role_admin;

  /// No description provided for @dashboard_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get dashboard_welcome;

  /// No description provided for @dashboard_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get dashboard_location;

  /// No description provided for @dashboard_latest_readings.
  ///
  /// In en, this message translates to:
  /// **'Latest Sensor Readings'**
  String get dashboard_latest_readings;

  /// No description provided for @dashboard_alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get dashboard_alerts;

  /// No description provided for @dashboard_quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboard_quick_actions;

  /// No description provided for @dashboard_capture_leaf.
  ///
  /// In en, this message translates to:
  /// **'Capture Leaf'**
  String get dashboard_capture_leaf;

  /// No description provided for @dashboard_view_recommendations.
  ///
  /// In en, this message translates to:
  /// **'View Recommendations'**
  String get dashboard_view_recommendations;

  /// No description provided for @dashboard_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get dashboard_analytics;

  /// No description provided for @sensor_soil_moisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get sensor_soil_moisture;

  /// No description provided for @sensor_soil_ph.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get sensor_soil_ph;

  /// No description provided for @sensor_nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get sensor_nitrogen;

  /// No description provided for @sensor_phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get sensor_phosphorus;

  /// No description provided for @sensor_potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get sensor_potassium;

  /// No description provided for @sensor_temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get sensor_temperature;

  /// No description provided for @sensor_humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get sensor_humidity;

  /// No description provided for @sensor_last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get sensor_last_updated;

  /// No description provided for @sensor_status_optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get sensor_status_optimal;

  /// No description provided for @sensor_status_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get sensor_status_warning;

  /// No description provided for @sensor_status_critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get sensor_status_critical;

  /// No description provided for @iot_title.
  ///
  /// In en, this message translates to:
  /// **'IoT Devices'**
  String get iot_title;

  /// No description provided for @iot_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get iot_connect;

  /// No description provided for @iot_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan for Devices'**
  String get iot_scan;

  /// No description provided for @iot_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get iot_bluetooth;

  /// No description provided for @iot_wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get iot_wifi;

  /// No description provided for @iot_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get iot_connected;

  /// No description provided for @iot_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get iot_disconnected;

  /// No description provided for @iot_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get iot_connecting;

  /// No description provided for @iot_pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get iot_pair;

  /// No description provided for @iot_unpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get iot_unpair;

  /// No description provided for @leaf_title.
  ///
  /// In en, this message translates to:
  /// **'Leaf Maturity Detection'**
  String get leaf_title;

  /// No description provided for @leaf_capture.
  ///
  /// In en, this message translates to:
  /// **'Capture Image'**
  String get leaf_capture;

  /// No description provided for @leaf_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get leaf_from_gallery;

  /// No description provided for @leaf_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get leaf_analyzing;

  /// No description provided for @leaf_results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get leaf_results;

  /// No description provided for @leaf_tender.
  ///
  /// In en, this message translates to:
  /// **'Tender Leaves'**
  String get leaf_tender;

  /// No description provided for @leaf_mature.
  ///
  /// In en, this message translates to:
  /// **'Mature Leaves'**
  String get leaf_mature;

  /// No description provided for @leaf_coarser.
  ///
  /// In en, this message translates to:
  /// **'Coarser Leaves'**
  String get leaf_coarser;

  /// No description provided for @leaf_confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get leaf_confidence;

  /// No description provided for @leaf_yield_prediction.
  ///
  /// In en, this message translates to:
  /// **'Yield Prediction'**
  String get leaf_yield_prediction;

  /// No description provided for @leaf_good_leaf_percentage.
  ///
  /// In en, this message translates to:
  /// **'Good Leaf %'**
  String get leaf_good_leaf_percentage;

  /// No description provided for @leaf_show_heatmap.
  ///
  /// In en, this message translates to:
  /// **'Show Heatmap'**
  String get leaf_show_heatmap;

  /// No description provided for @leaf_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get leaf_recommendation;

  /// No description provided for @disease_title.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get disease_title;

  /// No description provided for @disease_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan for Disease'**
  String get disease_scan;

  /// No description provided for @disease_type.
  ///
  /// In en, this message translates to:
  /// **'Disease Type'**
  String get disease_type;

  /// No description provided for @disease_severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get disease_severity;

  /// No description provided for @disease_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get disease_low;

  /// No description provided for @disease_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get disease_medium;

  /// No description provided for @disease_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get disease_high;

  /// No description provided for @disease_recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get disease_recommendations;

  /// No description provided for @disease_environmental_factors.
  ///
  /// In en, this message translates to:
  /// **'Environmental Factors'**
  String get disease_environmental_factors;

  /// No description provided for @fertilizer_title.
  ///
  /// In en, this message translates to:
  /// **'Fertilization Management'**
  String get fertilizer_title;

  /// No description provided for @fertilizer_current_levels.
  ///
  /// In en, this message translates to:
  /// **'Current NPK Levels'**
  String get fertilizer_current_levels;

  /// No description provided for @fertilizer_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get fertilizer_recommendation;

  /// No description provided for @fertilizer_type.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Type'**
  String get fertilizer_type;

  /// No description provided for @fertilizer_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fertilizer_quantity;

  /// No description provided for @fertilizer_application.
  ///
  /// In en, this message translates to:
  /// **'Application Method'**
  String get fertilizer_application;

  /// No description provided for @fertilizer_mark_applied.
  ///
  /// In en, this message translates to:
  /// **'Mark as Applied'**
  String get fertilizer_mark_applied;

  /// No description provided for @fertilizer_planning.
  ///
  /// In en, this message translates to:
  /// **'Fertilization Planning'**
  String get fertilizer_planning;

  /// No description provided for @fertilizer_whatif.
  ///
  /// In en, this message translates to:
  /// **'What-If Simulation'**
  String get fertilizer_whatif;

  /// No description provided for @powder_title.
  ///
  /// In en, this message translates to:
  /// **'Tea Powder Grading'**
  String get powder_title;

  /// No description provided for @powder_grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get powder_grade;

  /// No description provided for @powder_quality_score.
  ///
  /// In en, this message translates to:
  /// **'Quality Score'**
  String get powder_quality_score;

  /// No description provided for @powder_market_price.
  ///
  /// In en, this message translates to:
  /// **'Market Price'**
  String get powder_market_price;

  /// No description provided for @powder_price_trend.
  ///
  /// In en, this message translates to:
  /// **'Price Trend'**
  String get powder_price_trend;

  /// No description provided for @powder_rs_per_kg.
  ///
  /// In en, this message translates to:
  /// **'Rs/kg'**
  String get powder_rs_per_kg;

  /// No description provided for @admin_title.
  ///
  /// In en, this message translates to:
  /// **'System Administration'**
  String get admin_title;

  /// No description provided for @admin_users.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get admin_users;

  /// No description provided for @admin_devices.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get admin_devices;

  /// No description provided for @admin_config.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get admin_config;

  /// No description provided for @admin_sync.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization'**
  String get admin_sync;

  /// No description provided for @admin_logs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get admin_logs;

  /// No description provided for @alert_severity_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get alert_severity_info;

  /// No description provided for @alert_severity_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get alert_severity_warning;

  /// No description provided for @alert_severity_critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get alert_severity_critical;

  /// No description provided for @alert_mark_read.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get alert_mark_read;

  /// No description provided for @alert_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get alert_dismiss;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settings_profile;

  /// No description provided for @settings_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settings_logout;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
