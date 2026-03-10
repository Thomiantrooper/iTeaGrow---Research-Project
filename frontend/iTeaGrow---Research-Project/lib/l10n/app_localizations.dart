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

  /// No description provided for @sensor_ph_level.
  ///
  /// In en, this message translates to:
  /// **'pH Level'**
  String get sensor_ph_level;

  /// No description provided for @sensor_ec.
  ///
  /// In en, this message translates to:
  /// **'EC (µS/cm)'**
  String get sensor_ec;

  /// No description provided for @sensor_soil_temp.
  ///
  /// In en, this message translates to:
  /// **'Soil Temp'**
  String get sensor_soil_temp;

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

  /// No description provided for @nav_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get nav_help;

  /// No description provided for @nav_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get nav_notifications;

  /// No description provided for @nav_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get nav_reports;

  /// No description provided for @nav_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get nav_activity;

  /// No description provided for @nav_market_analysis.
  ///
  /// In en, this message translates to:
  /// **'Market Analysis'**
  String get nav_market_analysis;

  /// No description provided for @nav_yield_prediction.
  ///
  /// In en, this message translates to:
  /// **'Yield Prediction'**
  String get nav_yield_prediction;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get common_no_data;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get common_camera;

  /// No description provided for @common_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get common_gallery;

  /// No description provided for @common_generate_report.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get common_generate_report;

  /// No description provided for @common_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get common_online;

  /// No description provided for @common_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get common_offline;

  /// No description provided for @common_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get common_coming_soon;

  /// No description provided for @common_no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get common_no_internet;

  /// No description provided for @common_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get common_try_again;

  /// No description provided for @common_confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get common_confidence;

  /// No description provided for @common_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get common_history;

  /// No description provided for @login_welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String login_welcome_back(String name);

  /// No description provided for @login_invalid_creds.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get login_invalid_creds;

  /// No description provided for @splash_subtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered Tea Monitoring System'**
  String get splash_subtitle;

  /// No description provided for @splash_version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get splash_version;

  /// No description provided for @analytics_title.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics_title;

  /// No description provided for @analytics_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading analytics...'**
  String get analytics_loading;

  /// No description provided for @analytics_total_scans.
  ///
  /// In en, this message translates to:
  /// **'Total Scans'**
  String get analytics_total_scans;

  /// No description provided for @analytics_total_users.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get analytics_total_users;

  /// No description provided for @analytics_health_rate.
  ///
  /// In en, this message translates to:
  /// **'Health Rate'**
  String get analytics_health_rate;

  /// No description provided for @analytics_active_devices.
  ///
  /// In en, this message translates to:
  /// **'Active Devices'**
  String get analytics_active_devices;

  /// No description provided for @analytics_disease_distribution.
  ///
  /// In en, this message translates to:
  /// **'Disease Distribution'**
  String get analytics_disease_distribution;

  /// No description provided for @analytics_disease_trends.
  ///
  /// In en, this message translates to:
  /// **'Disease Trends'**
  String get analytics_disease_trends;

  /// No description provided for @analytics_monthly_scans.
  ///
  /// In en, this message translates to:
  /// **'Monthly Scans'**
  String get analytics_monthly_scans;

  /// No description provided for @analytics_recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery Tracking'**
  String get analytics_recovery;

  /// No description provided for @analytics_top_scanners.
  ///
  /// In en, this message translates to:
  /// **'Top Scanners'**
  String get analytics_top_scanners;

  /// No description provided for @analytics_recovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get analytics_recovered;

  /// No description provided for @analytics_improving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get analytics_improving;

  /// No description provided for @analytics_infected.
  ///
  /// In en, this message translates to:
  /// **'Infected'**
  String get analytics_infected;

  /// No description provided for @analytics_plants_tracked.
  ///
  /// In en, this message translates to:
  /// **'Plants Tracked'**
  String get analytics_plants_tracked;

  /// No description provided for @analytics_no_distribution.
  ///
  /// In en, this message translates to:
  /// **'No distribution data'**
  String get analytics_no_distribution;

  /// No description provided for @analytics_no_trend.
  ///
  /// In en, this message translates to:
  /// **'No trend data'**
  String get analytics_no_trend;

  /// No description provided for @analytics_no_yearly.
  ///
  /// In en, this message translates to:
  /// **'No yearly data'**
  String get analytics_no_yearly;

  /// No description provided for @analytics_no_recovery.
  ///
  /// In en, this message translates to:
  /// **'No recovery data'**
  String get analytics_no_recovery;

  /// No description provided for @analytics_no_scanners.
  ///
  /// In en, this message translates to:
  /// **'No scanner data'**
  String get analytics_no_scanners;

  /// No description provided for @leaf_analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze Leaf'**
  String get leaf_analyze;

  /// No description provided for @leaf_no_image.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get leaf_no_image;

  /// No description provided for @leaf_analysis_complete.
  ///
  /// In en, this message translates to:
  /// **'Analysis Complete'**
  String get leaf_analysis_complete;

  /// No description provided for @leaf_borderline_warning.
  ///
  /// In en, this message translates to:
  /// **'Maturity result is borderline — consider re-scanning under better lighting.'**
  String get leaf_borderline_warning;

  /// No description provided for @leaf_species_section.
  ///
  /// In en, this message translates to:
  /// **'Species Classification'**
  String get leaf_species_section;

  /// No description provided for @leaf_species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get leaf_species;

  /// No description provided for @leaf_confidence_level.
  ///
  /// In en, this message translates to:
  /// **'Confidence Level'**
  String get leaf_confidence_level;

  /// No description provided for @leaf_maturity_section.
  ///
  /// In en, this message translates to:
  /// **'Maturity Classification'**
  String get leaf_maturity_section;

  /// No description provided for @leaf_maturity_label.
  ///
  /// In en, this message translates to:
  /// **'Maturity'**
  String get leaf_maturity_label;

  /// No description provided for @leaf_yield_card_title.
  ///
  /// In en, this message translates to:
  /// **'Yield Prediction'**
  String get leaf_yield_card_title;

  /// No description provided for @leaf_yield_manager_feature.
  ///
  /// In en, this message translates to:
  /// **'Manager/Admin Feature'**
  String get leaf_yield_manager_feature;

  /// No description provided for @leaf_predict_yield.
  ///
  /// In en, this message translates to:
  /// **'Predict Yield'**
  String get leaf_predict_yield;

  /// No description provided for @leaf_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Image validation failed. Please try a clearer photo.'**
  String get leaf_validation_failed;

  /// No description provided for @leaf_yield_ready.
  ///
  /// In en, this message translates to:
  /// **'Yield prediction module - Ready for integration'**
  String get leaf_yield_ready;

  /// No description provided for @disease_scan_history.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get disease_scan_history;

  /// No description provided for @disease_new_scan.
  ///
  /// In en, this message translates to:
  /// **'New Scan'**
  String get disease_new_scan;

  /// No description provided for @disease_placeholder_title.
  ///
  /// In en, this message translates to:
  /// **'Scan Tea Leaf'**
  String get disease_placeholder_title;

  /// No description provided for @disease_placeholder_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture or upload an image of a tea leaf to detect diseases'**
  String get disease_placeholder_subtitle;

  /// No description provided for @disease_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Leaf...'**
  String get disease_analyzing;

  /// No description provided for @disease_detecting_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Detecting diseases'**
  String get disease_detecting_subtitle;

  /// No description provided for @disease_invalid_image.
  ///
  /// In en, this message translates to:
  /// **'Invalid Image'**
  String get disease_invalid_image;

  /// No description provided for @disease_healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy Leaf'**
  String get disease_healthy;

  /// No description provided for @disease_detected.
  ///
  /// In en, this message translates to:
  /// **'Disease Detected'**
  String get disease_detected;

  /// No description provided for @disease_not_tea_leaf.
  ///
  /// In en, this message translates to:
  /// **'Not a Tea Leaf'**
  String get disease_not_tea_leaf;

  /// No description provided for @disease_not_leaf_info.
  ///
  /// In en, this message translates to:
  /// **'Please capture a clear image of a tea leaf for accurate disease detection.'**
  String get disease_not_leaf_info;

  /// No description provided for @disease_scan_saved.
  ///
  /// In en, this message translates to:
  /// **'Scan saved to database'**
  String get disease_scan_saved;

  /// No description provided for @disease_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save scan'**
  String get disease_save_failed;

  /// No description provided for @disease_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get disease_saving;

  /// No description provided for @disease_severity_level.
  ///
  /// In en, this message translates to:
  /// **'Severity Level'**
  String get disease_severity_level;

  /// No description provided for @disease_no_analytics.
  ///
  /// In en, this message translates to:
  /// **'No analytics data available'**
  String get disease_no_analytics;

  /// No description provided for @disease_detection_confidence.
  ///
  /// In en, this message translates to:
  /// **'Detection Confidence'**
  String get disease_detection_confidence;

  /// No description provided for @disease_detection_analysis.
  ///
  /// In en, this message translates to:
  /// **'Detection Analysis'**
  String get disease_detection_analysis;

  /// No description provided for @disease_env_monitor.
  ///
  /// In en, this message translates to:
  /// **'Environment Monitor'**
  String get disease_env_monitor;

  /// No description provided for @disease_real_time.
  ///
  /// In en, this message translates to:
  /// **'Real-time conditions'**
  String get disease_real_time;

  /// No description provided for @disease_live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get disease_live;

  /// No description provided for @disease_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get disease_scanning;

  /// No description provided for @disease_start_scan.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get disease_start_scan;

  /// No description provided for @disease_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get disease_saved;

  /// No description provided for @disease_aqi.
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get disease_aqi;

  /// No description provided for @disease_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Image validation failed. Please try a clearer photo.'**
  String get disease_validation_failed;

  /// No description provided for @disease_please_rescan.
  ///
  /// In en, this message translates to:
  /// **'Please Rescan'**
  String get disease_please_rescan;

  /// No description provided for @disease_retake_photo.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get disease_retake_photo;

  /// No description provided for @disease_multi_leaf_active.
  ///
  /// In en, this message translates to:
  /// **'Multi-leaf mode active. Scan leaves one by one.'**
  String get disease_multi_leaf_active;

  /// No description provided for @disease_pdf_generated.
  ///
  /// In en, this message translates to:
  /// **'PDF report generated'**
  String get disease_pdf_generated;

  /// No description provided for @disease_multi_leaf_pdf_ready.
  ///
  /// In en, this message translates to:
  /// **'Multi-leaf PDF report ready'**
  String get disease_multi_leaf_pdf_ready;

  /// No description provided for @disease_view_pdf_report.
  ///
  /// In en, this message translates to:
  /// **'View PDF Report'**
  String get disease_view_pdf_report;

  /// No description provided for @disease_new_session.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get disease_new_session;

  /// No description provided for @disease_scan_next_leaf.
  ///
  /// In en, this message translates to:
  /// **'Scan Next Leaf'**
  String get disease_scan_next_leaf;

  /// No description provided for @disease_finish_report.
  ///
  /// In en, this message translates to:
  /// **'Finish & Report'**
  String get disease_finish_report;

  /// No description provided for @disease_treatment_guide.
  ///
  /// In en, this message translates to:
  /// **'View Full Treatment Guide'**
  String get disease_treatment_guide;

  /// No description provided for @disease_generate_report_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report'**
  String get disease_generate_report_failed;

  /// No description provided for @disease_detection_metrics.
  ///
  /// In en, this message translates to:
  /// **'Detection Metrics'**
  String get disease_detection_metrics;

  /// No description provided for @disease_view_report.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get disease_view_report;

  /// No description provided for @disease_detected_with_confidence.
  ///
  /// In en, this message translates to:
  /// **'Disease detected with {level} confidence.'**
  String disease_detected_with_confidence(String level);

  /// No description provided for @disease_reliability_display.
  ///
  /// In en, this message translates to:
  /// **'Reliability: {level}'**
  String disease_reliability_display(String level);

  /// No description provided for @disease_reliability_very_high.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get disease_reliability_very_high;

  /// No description provided for @disease_reliability_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get disease_reliability_high;

  /// No description provided for @disease_reliability_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get disease_reliability_moderate;

  /// No description provided for @disease_reliability_low_level.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get disease_reliability_low_level;

  /// No description provided for @disease_reliability_very_low.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get disease_reliability_very_low;

  /// No description provided for @disease_backend_offline.
  ///
  /// In en, this message translates to:
  /// **'Backend Offline'**
  String get disease_backend_offline;

  /// No description provided for @disease_backend_offline_desc.
  ///
  /// In en, this message translates to:
  /// **'The ML server is unavailable. Analysis requires a live connection.'**
  String get disease_backend_offline_desc;

  /// No description provided for @disease_not_leaf_desc.
  ///
  /// In en, this message translates to:
  /// **'The uploaded image is not a recognizable tea leaf.'**
  String get disease_not_leaf_desc;

  /// No description provided for @disease_healthy_label.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get disease_healthy_label;

  /// No description provided for @disease_no_diseases.
  ///
  /// In en, this message translates to:
  /// **'No diseases detected. Leaf appears healthy.'**
  String get disease_no_diseases;

  /// No description provided for @disease_false_positive_warning.
  ///
  /// In en, this message translates to:
  /// **'Possible false positive — glare or bright light detected.'**
  String get disease_false_positive_warning;

  /// No description provided for @disease_analyze_leaf.
  ///
  /// In en, this message translates to:
  /// **'Analyze Leaf'**
  String get disease_analyze_leaf;

  /// No description provided for @disease_sending_to_ai.
  ///
  /// In en, this message translates to:
  /// **'Sending to AI model'**
  String get disease_sending_to_ai;

  /// No description provided for @disease_running_local.
  ///
  /// In en, this message translates to:
  /// **'Running local analysis'**
  String get disease_running_local;

  /// No description provided for @disease_scan_instructions.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo or select from gallery.\nSupported: JPG, PNG, WebP (max 20 MB)'**
  String get disease_scan_instructions;

  /// No description provided for @disease_temp_label.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get disease_temp_label;

  /// No description provided for @disease_live_label.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get disease_live_label;

  /// No description provided for @disease_default_label.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get disease_default_label;

  /// No description provided for @disease_processing_label.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get disease_processing_label;

  /// No description provided for @disease_image_quality_label.
  ///
  /// In en, this message translates to:
  /// **'Image Quality'**
  String get disease_image_quality_label;

  /// No description provided for @powder_capture_image.
  ///
  /// In en, this message translates to:
  /// **'Capture Powder Image'**
  String get powder_capture_image;

  /// No description provided for @powder_grade_action.
  ///
  /// In en, this message translates to:
  /// **'Grade Powder'**
  String get powder_grade_action;

  /// No description provided for @powder_grading.
  ///
  /// In en, this message translates to:
  /// **'Grading...'**
  String get powder_grading;

  /// No description provided for @powder_no_image.
  ///
  /// In en, this message translates to:
  /// **'No Powder Image Selected'**
  String get powder_no_image;

  /// No description provided for @powder_no_image_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture or upload an image to begin grading.'**
  String get powder_no_image_subtitle;

  /// No description provided for @powder_results.
  ///
  /// In en, this message translates to:
  /// **'Grading Results'**
  String get powder_results;

  /// No description provided for @powder_borderline.
  ///
  /// In en, this message translates to:
  /// **'Grade result is borderline — consider re-scanning under better lighting.'**
  String get powder_borderline;

  /// No description provided for @powder_confidence_level.
  ///
  /// In en, this message translates to:
  /// **'Confidence Level'**
  String get powder_confidence_level;

  /// No description provided for @powder_local_source.
  ///
  /// In en, this message translates to:
  /// **'Processing Source: Local ML Model'**
  String get powder_local_source;

  /// No description provided for @powder_cloud_source.
  ///
  /// In en, this message translates to:
  /// **'Processing Source: Cloud Server'**
  String get powder_cloud_source;

  /// No description provided for @powder_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Image validation failed. Please try a clearer photo.'**
  String get powder_validation_failed;

  /// No description provided for @powder_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset and Retake'**
  String get powder_reset;

  /// No description provided for @soil_select_zone.
  ///
  /// In en, this message translates to:
  /// **'Select Plantation Zone'**
  String get soil_select_zone;

  /// No description provided for @soil_select_block.
  ///
  /// In en, this message translates to:
  /// **'Select Block'**
  String get soil_select_block;

  /// No description provided for @soil_select_sector.
  ///
  /// In en, this message translates to:
  /// **'Select Sector'**
  String get soil_select_sector;

  /// No description provided for @soil_report_title.
  ///
  /// In en, this message translates to:
  /// **'Soil Health Report'**
  String get soil_report_title;

  /// No description provided for @soil_condition_label.
  ///
  /// In en, this message translates to:
  /// **'SOIL CONDITION REPORT'**
  String get soil_condition_label;

  /// No description provided for @soil_optimal_msg.
  ///
  /// In en, this message translates to:
  /// **'Optimal condition. No major fertilizer adjustments required.'**
  String get soil_optimal_msg;

  /// No description provided for @soil_action_msg.
  ///
  /// In en, this message translates to:
  /// **'Action required. Significant imbalances found in soil chemistry.'**
  String get soil_action_msg;

  /// No description provided for @soil_required_actions.
  ///
  /// In en, this message translates to:
  /// **'Required Actions'**
  String get soil_required_actions;

  /// No description provided for @soil_chemistry_details.
  ///
  /// In en, this message translates to:
  /// **'Soil Chemistry Details'**
  String get soil_chemistry_details;

  /// No description provided for @soil_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data report generated'**
  String get soil_no_data;

  /// No description provided for @soil_prev_block.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS BLOCK'**
  String get soil_prev_block;

  /// No description provided for @soil_next_block.
  ///
  /// In en, this message translates to:
  /// **'NEXT BLOCK'**
  String get soil_next_block;

  /// No description provided for @soil_nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get soil_nitrogen;

  /// No description provided for @soil_phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get soil_phosphorus;

  /// No description provided for @soil_potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get soil_potassium;

  /// No description provided for @soil_ph.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get soil_ph;

  /// No description provided for @soil_humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get soil_humidity;

  /// No description provided for @soil_zone_overview.
  ///
  /// In en, this message translates to:
  /// **'Zone Overview'**
  String get soil_zone_overview;

  /// No description provided for @soil_block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get soil_block;

  /// No description provided for @soil_analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get soil_analysis;

  /// No description provided for @soil_sensor_level.
  ///
  /// In en, this message translates to:
  /// **'Sensor Level'**
  String get soil_sensor_level;

  /// No description provided for @soil_status_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get soil_status_low;

  /// No description provided for @soil_status_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get soil_status_high;

  /// No description provided for @soil_status_optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get soil_status_optimal;

  /// No description provided for @soil_status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get soil_status_label;

  /// No description provided for @soil_optimal_range.
  ///
  /// In en, this message translates to:
  /// **'Optimal Range'**
  String get soil_optimal_range;

  /// No description provided for @soil_report_for.
  ///
  /// In en, this message translates to:
  /// **'Report for'**
  String get soil_report_for;

  /// No description provided for @zone_label.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone_label;

  /// No description provided for @soil_at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get soil_at;

  /// No description provided for @zone_north.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get zone_north;

  /// No description provided for @zone_east.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get zone_east;

  /// No description provided for @zone_south.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get zone_south;

  /// No description provided for @zone_west.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get zone_west;

  /// No description provided for @zone_central.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get zone_central;

  /// No description provided for @iot_devices_heading.
  ///
  /// In en, this message translates to:
  /// **'Connected Devices'**
  String get iot_devices_heading;

  /// No description provided for @iot_devices_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor your tea plantation environmental conditions'**
  String get iot_devices_subtitle;

  /// No description provided for @iot_air_quality.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get iot_air_quality;

  /// No description provided for @iot_env_device.
  ///
  /// In en, this message translates to:
  /// **'IoTENV'**
  String get iot_env_device;

  /// No description provided for @iot_env_device_desc.
  ///
  /// In en, this message translates to:
  /// **'Environmental Monitoring'**
  String get iot_env_device_desc;

  /// No description provided for @iot_soil_device.
  ///
  /// In en, this message translates to:
  /// **'IoTSOIL'**
  String get iot_soil_device;

  /// No description provided for @iot_soil_device_desc.
  ///
  /// In en, this message translates to:
  /// **'Soil Monitoring'**
  String get iot_soil_device_desc;

  /// No description provided for @iot_auto_update.
  ///
  /// In en, this message translates to:
  /// **'Devices update automatically every 5 seconds when online'**
  String get iot_auto_update;

  /// No description provided for @iot_soil_soon.
  ///
  /// In en, this message translates to:
  /// **'Soil monitoring device will be available soon with NPK, moisture, and pH sensors'**
  String get iot_soil_soon;

  /// No description provided for @iot_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available. Waiting for device connection...'**
  String get iot_no_data;

  /// No description provided for @iot_last_update.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get iot_last_update;

  /// No description provided for @iot_aqi_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get iot_aqi_good;

  /// No description provided for @iot_aqi_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get iot_aqi_moderate;

  /// No description provided for @iot_aqi_unhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get iot_aqi_unhealthy;

  /// No description provided for @iot_aqi_bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get iot_aqi_bad;

  /// No description provided for @iot_aqi_hazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get iot_aqi_hazardous;

  /// No description provided for @market_title.
  ///
  /// In en, this message translates to:
  /// **'Tea Price Predictor'**
  String get market_title;

  /// No description provided for @market_no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect internet.'**
  String get market_no_internet;

  /// No description provided for @market_select_grade.
  ///
  /// In en, this message translates to:
  /// **'Or Select Tea Grade Manually'**
  String get market_select_grade;

  /// No description provided for @market_your_quality.
  ///
  /// In en, this message translates to:
  /// **'Your Tea Quality'**
  String get market_your_quality;

  /// No description provided for @market_tap_capture.
  ///
  /// In en, this message translates to:
  /// **'Tap to Capture / Upload Tea Powder'**
  String get market_tap_capture;

  /// No description provided for @market_detected_grade.
  ///
  /// In en, this message translates to:
  /// **'Detected Grade'**
  String get market_detected_grade;

  /// No description provided for @market_local_ai.
  ///
  /// In en, this message translates to:
  /// **'Local AI'**
  String get market_local_ai;

  /// No description provided for @market_cloud_ai.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get market_cloud_ai;

  /// No description provided for @market_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get market_take_photo;

  /// No description provided for @market_tea_grade.
  ///
  /// In en, this message translates to:
  /// **'Tea Grade'**
  String get market_tea_grade;

  /// No description provided for @market_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get market_color;

  /// No description provided for @market_aroma.
  ///
  /// In en, this message translates to:
  /// **'Aroma'**
  String get market_aroma;

  /// No description provided for @market_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get market_age;

  /// No description provided for @market_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get market_premium;

  /// No description provided for @market_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get market_normal;

  /// No description provided for @market_dull.
  ///
  /// In en, this message translates to:
  /// **'Dull'**
  String get market_dull;

  /// No description provided for @market_strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get market_strong;

  /// No description provided for @market_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get market_moderate;

  /// No description provided for @market_weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get market_weak;

  /// No description provided for @market_fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh (<7 days)'**
  String get market_fresh;

  /// No description provided for @market_medium_age.
  ///
  /// In en, this message translates to:
  /// **'Medium (7-21 days)'**
  String get market_medium_age;

  /// No description provided for @market_old.
  ///
  /// In en, this message translates to:
  /// **'Old (>21 days)'**
  String get market_old;

  /// No description provided for @market_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get market_quantity;

  /// No description provided for @market_prediction_result.
  ///
  /// In en, this message translates to:
  /// **'Prediction Result'**
  String get market_prediction_result;

  /// No description provided for @market_no_data.
  ///
  /// In en, this message translates to:
  /// **'No market data available'**
  String get market_no_data;

  /// No description provided for @market_calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate Market Price'**
  String get market_calculate;

  /// No description provided for @market_result.
  ///
  /// In en, this message translates to:
  /// **'Prediction Result'**
  String get market_result;

  /// No description provided for @market_base_price.
  ///
  /// In en, this message translates to:
  /// **'Base Price (Live)'**
  String get market_base_price;

  /// No description provided for @market_insights.
  ///
  /// In en, this message translates to:
  /// **'Market Insights'**
  String get market_insights;

  /// No description provided for @market_quality_analysis.
  ///
  /// In en, this message translates to:
  /// **'My Quality Analysis'**
  String get market_quality_analysis;

  /// No description provided for @market_quality_impact.
  ///
  /// In en, this message translates to:
  /// **'Impact of your tea attributes on price'**
  String get market_quality_impact;

  /// No description provided for @market_grade_comparison.
  ///
  /// In en, this message translates to:
  /// **'Grade Value Comparison'**
  String get market_grade_comparison;

  /// No description provided for @market_grade_benchmarks.
  ///
  /// In en, this message translates to:
  /// **'Current Rs./kg benchmarks'**
  String get market_grade_benchmarks;

  /// No description provided for @market_historical.
  ///
  /// In en, this message translates to:
  /// **'Historical Market Trends'**
  String get market_historical;

  /// No description provided for @market_historical_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Past 3-6 months performance'**
  String get market_historical_subtitle;

  /// No description provided for @market_managers_insight.
  ///
  /// In en, this message translates to:
  /// **'Manager\'s Insight'**
  String get market_managers_insight;

  /// No description provided for @market_report_title.
  ///
  /// In en, this message translates to:
  /// **'Price Report Setup'**
  String get market_report_title;

  /// No description provided for @market_date_filtering.
  ///
  /// In en, this message translates to:
  /// **'Date Filtering'**
  String get market_date_filtering;

  /// No description provided for @market_select_date_range.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get market_select_date_range;

  /// No description provided for @market_clear_filter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get market_clear_filter;

  /// No description provided for @market_admin_title.
  ///
  /// In en, this message translates to:
  /// **'Admin Price Update'**
  String get market_admin_title;

  /// No description provided for @market_weekly_prices.
  ///
  /// In en, this message translates to:
  /// **'Enter Weekly Auction Prices'**
  String get market_weekly_prices;

  /// No description provided for @market_save_publish.
  ///
  /// In en, this message translates to:
  /// **'Save & Publish Prices'**
  String get market_save_publish;

  /// No description provided for @market_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Server'**
  String get market_connected;

  /// No description provided for @market_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected - Check your internet'**
  String get market_disconnected;

  /// No description provided for @market_source.
  ///
  /// In en, this message translates to:
  /// **'Market Source'**
  String get market_source;

  /// No description provided for @market_auction_notes.
  ///
  /// In en, this message translates to:
  /// **'Auction Notes'**
  String get market_auction_notes;

  /// No description provided for @market_prev_auctions.
  ///
  /// In en, this message translates to:
  /// **'Previous Auction Prices'**
  String get market_prev_auctions;

  /// No description provided for @market_week_of.
  ///
  /// In en, this message translates to:
  /// **'Week of'**
  String get market_week_of;

  /// No description provided for @market_published.
  ///
  /// In en, this message translates to:
  /// **'Prices published to AI Model!'**
  String get market_published;

  /// No description provided for @market_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prices'**
  String get market_load_failed;

  /// No description provided for @market_image_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Image validation failed. Please try a clearer photo.'**
  String get market_image_validation_failed;

  /// No description provided for @market_scan_confidence_advisory.
  ///
  /// In en, this message translates to:
  /// **'Scan confidence is {confidenceLabel} — price will be calculated using the detected grade ({grade}), but consider re-scanning for accuracy.'**
  String market_scan_confidence_advisory(String confidenceLabel, String grade);

  /// No description provided for @market_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading markets'**
  String get market_error_loading;

  /// No description provided for @market_managers_insight_label.
  ///
  /// In en, this message translates to:
  /// **'Manager\'s Insight'**
  String get market_managers_insight_label;

  /// No description provided for @market_insight_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent quality! Your tea meets all premium benchmarks. This will likely fetch the highest market price.'**
  String get market_insight_excellent;

  /// No description provided for @market_insight_color_low.
  ///
  /// In en, this message translates to:
  /// **'Your tea color is below premium levels. Consider checking your drying temperature and processing speed to avoid dullness.'**
  String get market_insight_color_low;

  /// No description provided for @market_insight_aroma_low.
  ///
  /// In en, this message translates to:
  /// **'The aroma profile is weak. This often happens due to over-fermentation. Monitor your fermentation duration more closely.'**
  String get market_insight_aroma_low;

  /// No description provided for @market_insight_freshness_low.
  ///
  /// In en, this message translates to:
  /// **'Freshness is the main issue. Old tea powder loses its \'bite\' and market value. Process and pack your batches faster.'**
  String get market_insight_freshness_low;

  /// No description provided for @soil_health_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get soil_health_good;

  /// No description provided for @soil_health_fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get soil_health_fair;

  /// No description provided for @soil_health_poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get soil_health_poor;

  /// No description provided for @soil_health_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get soil_health_unknown;

  /// No description provided for @soil_rec_n_low.
  ///
  /// In en, this message translates to:
  /// **'Apply nitrogen fertilizer (Urea 50kg/ha)'**
  String get soil_rec_n_low;

  /// No description provided for @soil_rec_p_low.
  ///
  /// In en, this message translates to:
  /// **'Apply phosphorus fertilizer (SSP 40kg/ha)'**
  String get soil_rec_p_low;

  /// No description provided for @soil_rec_k_low.
  ///
  /// In en, this message translates to:
  /// **'Apply potassium fertilizer (MOP 60kg/ha)'**
  String get soil_rec_k_low;

  /// No description provided for @soil_rec_ph_low.
  ///
  /// In en, this message translates to:
  /// **'Apply lime to increase pH (1 ton/ha)'**
  String get soil_rec_ph_low;

  /// No description provided for @soil_rec_ec_low.
  ///
  /// In en, this message translates to:
  /// **'Consider organic matter addition'**
  String get soil_rec_ec_low;

  /// No description provided for @soil_rec_temp_low.
  ///
  /// In en, this message translates to:
  /// **'Soil temperature low - consider mulching'**
  String get soil_rec_temp_low;

  /// No description provided for @soil_rec_humidity_low.
  ///
  /// In en, this message translates to:
  /// **'Irrigation needed - humidity too low'**
  String get soil_rec_humidity_low;

  /// No description provided for @soil_rec_n_high.
  ///
  /// In en, this message translates to:
  /// **'REDUCE nitrogen - excess causing poor health'**
  String get soil_rec_n_high;

  /// No description provided for @soil_rec_p_high.
  ///
  /// In en, this message translates to:
  /// **'REDUCE phosphorus - excess causing imbalance'**
  String get soil_rec_p_high;

  /// No description provided for @soil_rec_k_high.
  ///
  /// In en, this message translates to:
  /// **'REDUCE potassium - excess causing poor health'**
  String get soil_rec_k_high;

  /// No description provided for @soil_rec_ph_high.
  ///
  /// In en, this message translates to:
  /// **'Apply sulfur to lower pH'**
  String get soil_rec_ph_high;

  /// No description provided for @soil_rec_ec_high.
  ///
  /// In en, this message translates to:
  /// **'High salinity - improve drainage, leach soil'**
  String get soil_rec_ec_high;

  /// No description provided for @soil_rec_temp_high.
  ///
  /// In en, this message translates to:
  /// **'Temperature too high - provide shade'**
  String get soil_rec_temp_high;

  /// No description provided for @soil_rec_humidity_high.
  ///
  /// In en, this message translates to:
  /// **'Humidity too high - improve ventilation'**
  String get soil_rec_humidity_high;

  /// No description provided for @soil_rec_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain current practice'**
  String get soil_rec_maintain;

  /// No description provided for @soil_rec_soil_good.
  ///
  /// In en, this message translates to:
  /// **'Soil health is optimal'**
  String get soil_rec_soil_good;

  /// No description provided for @soil_rec_poor_general.
  ///
  /// In en, this message translates to:
  /// **'Soil health is poor - conduct detailed soil analysis'**
  String get soil_rec_poor_general;

  /// No description provided for @soil_rec_amendment.
  ///
  /// In en, this message translates to:
  /// **'Consider soil amendment and organic matter addition'**
  String get soil_rec_amendment;

  /// No description provided for @map_never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get map_never;

  /// No description provided for @map_ml_engine.
  ///
  /// In en, this message translates to:
  /// **'ML ENGINE'**
  String get map_ml_engine;

  /// No description provided for @map_tri_standards.
  ///
  /// In en, this message translates to:
  /// **'TRI STANDARDS'**
  String get map_tri_standards;

  /// No description provided for @soil_pdf_export_title.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get soil_pdf_export_title;

  /// No description provided for @error_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String error_camera(String error);

  /// No description provided for @error_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery error: {error}'**
  String error_gallery(String error);

  /// No description provided for @error_analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis error: {error}'**
  String error_analysis(String error);

  /// No description provided for @error_analysis_failed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {error}'**
  String error_analysis_failed(String error);

  /// No description provided for @error_report_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report: {error}'**
  String error_report_failed(String error);

  /// No description provided for @disease_connected_backend.
  ///
  /// In en, this message translates to:
  /// **'Connected to backend server'**
  String get disease_connected_backend;

  /// No description provided for @disease_backend_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Backend not available - using offline mode'**
  String get disease_backend_unavailable;

  /// No description provided for @disease_connected_ml.
  ///
  /// In en, this message translates to:
  /// **'Connected to ML backend'**
  String get disease_connected_ml;

  /// No description provided for @disease_backend_offline_local.
  ///
  /// In en, this message translates to:
  /// **'Backend offline — using local mode'**
  String get disease_backend_offline_local;

  /// No description provided for @disease_detected_result.
  ///
  /// In en, this message translates to:
  /// **'Detected: {disease} ({confidence}%)'**
  String disease_detected_result(String disease, String confidence);

  /// No description provided for @disease_save_db_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save to database. Check connection or login status.'**
  String get disease_save_db_failed;

  /// No description provided for @disease_multi_leaf_report_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate multi-leaf report: {error}'**
  String disease_multi_leaf_report_failed(String error);

  /// No description provided for @disease_unsupported_file.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: {ext}. Use JPG, PNG, or WebP.'**
  String disease_unsupported_file(String ext);

  /// No description provided for @disease_image_too_small.
  ///
  /// In en, this message translates to:
  /// **'Image too small ({size} KB). May be corrupt.'**
  String disease_image_too_small(String size);

  /// No description provided for @disease_image_too_large.
  ///
  /// In en, this message translates to:
  /// **'Image too large. Maximum 20 MB.'**
  String get disease_image_too_large;

  /// No description provided for @scan_history_login_required.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view scan history.'**
  String get scan_history_login_required;

  /// No description provided for @scan_history_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {error}'**
  String scan_history_load_failed(String error);

  /// No description provided for @scan_history_tab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get scan_history_tab;

  /// No description provided for @scan_history_empty.
  ///
  /// In en, this message translates to:
  /// **'No scan history yet'**
  String get scan_history_empty;

  /// No description provided for @scan_history_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start scanning tea leaves to see your history here'**
  String get scan_history_empty_subtitle;

  /// No description provided for @scan_history_confidence_pct.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {value}%'**
  String scan_history_confidence_pct(String value);

  /// No description provided for @scan_history_overall_health.
  ///
  /// In en, this message translates to:
  /// **'Overall Health Rate'**
  String get scan_history_overall_health;

  /// No description provided for @scan_history_severity_levels.
  ///
  /// In en, this message translates to:
  /// **'Severity Levels'**
  String get scan_history_severity_levels;

  /// No description provided for @scan_history_detection_details.
  ///
  /// In en, this message translates to:
  /// **'Detection Details'**
  String get scan_history_detection_details;

  /// No description provided for @scan_history_detected_at.
  ///
  /// In en, this message translates to:
  /// **'Detected At'**
  String get scan_history_detected_at;

  /// No description provided for @scan_history_env_conditions.
  ///
  /// In en, this message translates to:
  /// **'Environmental Conditions'**
  String get scan_history_env_conditions;

  /// No description provided for @scan_history_healthy_leaf.
  ///
  /// In en, this message translates to:
  /// **'Healthy Tea Leaf'**
  String get scan_history_healthy_leaf;

  /// No description provided for @leaf_analyzed_at.
  ///
  /// In en, this message translates to:
  /// **'Analyzed at: {time}'**
  String leaf_analyzed_at(String time);

  /// No description provided for @yield_internet_required.
  ///
  /// In en, this message translates to:
  /// **'Internet connection required for yield prediction'**
  String get yield_internet_required;

  /// No description provided for @yield_max_workers.
  ///
  /// In en, this message translates to:
  /// **'Value seems unrealistic (max 500 workers)'**
  String get yield_max_workers;

  /// No description provided for @yield_max_ha.
  ///
  /// In en, this message translates to:
  /// **'Value seems unrealistic (max 500 ha)'**
  String get yield_max_ha;

  /// No description provided for @yield_max_crop.
  ///
  /// In en, this message translates to:
  /// **'Value seems unrealistic (max 500,000 kg)'**
  String get yield_max_crop;

  /// No description provided for @yield_pct_range.
  ///
  /// In en, this message translates to:
  /// **'Must be between 0 and 100'**
  String get yield_pct_range;

  /// No description provided for @yield_results_weather_source.
  ///
  /// In en, this message translates to:
  /// **'Weather Source: {source}'**
  String yield_results_weather_source(String source);

  /// No description provided for @yield_title.
  ///
  /// In en, this message translates to:
  /// **'Tea Yield Prediction'**
  String get yield_title;

  /// No description provided for @yield_no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect to use yield prediction.'**
  String get yield_no_internet;

  /// No description provided for @yield_division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get yield_division;

  /// No description provided for @yield_workers.
  ///
  /// In en, this message translates to:
  /// **'Number of Workers'**
  String get yield_workers;

  /// No description provided for @yield_workers_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 56'**
  String get yield_workers_hint;

  /// No description provided for @yield_field_size.
  ///
  /// In en, this message translates to:
  /// **'Field Size (hectares)'**
  String get yield_field_size;

  /// No description provided for @yield_field_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 6.59'**
  String get yield_field_hint;

  /// No description provided for @yield_crop.
  ///
  /// In en, this message translates to:
  /// **'Crop Harvested (kg)'**
  String get yield_crop;

  /// No description provided for @yield_crop_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1036'**
  String get yield_crop_hint;

  /// No description provided for @yield_grade_percentages.
  ///
  /// In en, this message translates to:
  /// **'Tea Grade Percentages'**
  String get yield_grade_percentages;

  /// No description provided for @yield_grade_g.
  ///
  /// In en, this message translates to:
  /// **'Grade G (%)'**
  String get yield_grade_g;

  /// No description provided for @yield_grade_c.
  ///
  /// In en, this message translates to:
  /// **'Grade C (%)'**
  String get yield_grade_c;

  /// No description provided for @yield_grade_d.
  ///
  /// In en, this message translates to:
  /// **'Grade D (%)'**
  String get yield_grade_d;

  /// No description provided for @yield_total.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get yield_total;

  /// No description provided for @yield_pct_warning.
  ///
  /// In en, this message translates to:
  /// **'Percentages must sum to 100%'**
  String get yield_pct_warning;

  /// No description provided for @yield_prediction_days.
  ///
  /// In en, this message translates to:
  /// **'Prediction Days'**
  String get yield_prediction_days;

  /// No description provided for @yield_get_prediction.
  ///
  /// In en, this message translates to:
  /// **'Get Prediction'**
  String get yield_get_prediction;

  /// No description provided for @yield_valid_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get yield_valid_number;

  /// No description provided for @yield_greater_than_zero.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get yield_greater_than_zero;

  /// No description provided for @yield_results_title.
  ///
  /// In en, this message translates to:
  /// **'Prediction Results'**
  String get yield_results_title;

  /// No description provided for @yield_results_charts_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to show detailed charts'**
  String get yield_results_charts_hint;

  /// No description provided for @yield_total_predicted.
  ///
  /// In en, this message translates to:
  /// **'Total Predicted Yield'**
  String get yield_total_predicted;

  /// No description provided for @notif_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notif_title;

  /// No description provided for @notif_mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notif_mark_all_read;

  /// No description provided for @notif_tab_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notif_tab_all;

  /// No description provided for @notif_tab_alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notif_tab_alerts;

  /// No description provided for @notif_tab_updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notif_tab_updates;

  /// No description provided for @notif_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notif_empty;

  /// No description provided for @notif_all_marked_read.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notif_all_marked_read;

  /// No description provided for @notif_deleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notif_deleted;

  /// No description provided for @activity_title.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activity_title;

  /// No description provided for @activity_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activity_filter_all;

  /// No description provided for @activity_filter_scans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get activity_filter_scans;

  /// No description provided for @activity_filter_harvests.
  ///
  /// In en, this message translates to:
  /// **'Harvests'**
  String get activity_filter_harvests;

  /// No description provided for @activity_filter_iot.
  ///
  /// In en, this message translates to:
  /// **'IoT'**
  String get activity_filter_iot;

  /// No description provided for @activity_filter_alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get activity_filter_alerts;

  /// No description provided for @activity_empty.
  ///
  /// In en, this message translates to:
  /// **'No activities found'**
  String get activity_empty;

  /// No description provided for @activity_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your activities will appear here'**
  String get activity_empty_subtitle;

  /// No description provided for @activity_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get activity_today;

  /// No description provided for @activity_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get activity_yesterday;

  /// No description provided for @reports_all.
  ///
  /// In en, this message translates to:
  /// **'All Reports'**
  String get reports_all;

  /// No description provided for @reports_mine.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get reports_mine;

  /// No description provided for @reports_empty.
  ///
  /// In en, this message translates to:
  /// **'No scan records found'**
  String get reports_empty;

  /// No description provided for @reports_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan tea leaves to generate reports'**
  String get reports_empty_subtitle;

  /// No description provided for @reports_label.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reports_label;

  /// No description provided for @reports_preview_title.
  ///
  /// In en, this message translates to:
  /// **'Report Preview'**
  String get reports_preview_title;

  /// No description provided for @reports_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get reports_generating;

  /// No description provided for @reports_no_pdf.
  ///
  /// In en, this message translates to:
  /// **'No PDF generated'**
  String get reports_no_pdf;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get help_title;

  /// No description provided for @help_header.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get help_header;

  /// No description provided for @help_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search for help...'**
  String get help_search_hint;

  /// No description provided for @help_quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get help_quick_actions;

  /// No description provided for @help_chat_support.
  ///
  /// In en, this message translates to:
  /// **'Chat Support'**
  String get help_chat_support;

  /// No description provided for @help_faq_section.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get help_faq_section;

  /// No description provided for @help_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get help_no_results;

  /// No description provided for @help_no_results_hint.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get help_no_results_hint;

  /// No description provided for @map_title.
  ///
  /// In en, this message translates to:
  /// **'Plantation Map'**
  String get map_title;

  /// No description provided for @map_stat_healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get map_stat_healthy;

  /// No description provided for @map_stat_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get map_stat_active;

  /// No description provided for @map_stat_critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get map_stat_critical;

  /// No description provided for @map_legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get map_legend;

  /// No description provided for @map_legend_good.
  ///
  /// In en, this message translates to:
  /// **'Good — Healthy Soil'**
  String get map_legend_good;

  /// No description provided for @map_legend_fair.
  ///
  /// In en, this message translates to:
  /// **'Fair — Needs Attention'**
  String get map_legend_fair;

  /// No description provided for @map_legend_poor.
  ///
  /// In en, this message translates to:
  /// **'Poor — Critical Status'**
  String get map_legend_poor;

  /// No description provided for @map_legend_no_data.
  ///
  /// In en, this message translates to:
  /// **'No Data / Offline'**
  String get map_legend_no_data;

  /// No description provided for @map_divisions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'25 divisions • live monitoring'**
  String get map_divisions_subtitle;

  /// No description provided for @map_sectors_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sub-division mapping • 25 sectors'**
  String get map_sectors_subtitle;

  /// No description provided for @map_zone_north.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get map_zone_north;

  /// No description provided for @map_zone_east.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get map_zone_east;

  /// No description provided for @map_zone_south.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get map_zone_south;

  /// No description provided for @map_zone_west.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get map_zone_west;

  /// No description provided for @map_zone_central.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get map_zone_central;

  /// No description provided for @map_zone_north_full.
  ///
  /// In en, this message translates to:
  /// **'North Zone'**
  String get map_zone_north_full;

  /// No description provided for @map_zone_east_full.
  ///
  /// In en, this message translates to:
  /// **'East Zone'**
  String get map_zone_east_full;

  /// No description provided for @map_zone_south_full.
  ///
  /// In en, this message translates to:
  /// **'South Zone'**
  String get map_zone_south_full;

  /// No description provided for @map_zone_west_full.
  ///
  /// In en, this message translates to:
  /// **'West Zone'**
  String get map_zone_west_full;

  /// No description provided for @map_zone_central_full.
  ///
  /// In en, this message translates to:
  /// **'Central Zone'**
  String get map_zone_central_full;

  /// No description provided for @map_block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get map_block;

  /// No description provided for @map_division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get map_division;

  /// No description provided for @map_soil_details_title.
  ///
  /// In en, this message translates to:
  /// **'Soil Data Details'**
  String get map_soil_details_title;

  /// No description provided for @map_recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get map_recommendations;

  /// No description provided for @map_no_recommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available.'**
  String get map_no_recommendations;

  /// No description provided for @map_soil_status_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get map_soil_status_low;

  /// No description provided for @map_soil_status_slightly_high.
  ///
  /// In en, this message translates to:
  /// **'Slightly High'**
  String get map_soil_status_slightly_high;

  /// No description provided for @map_soil_status_excessive.
  ///
  /// In en, this message translates to:
  /// **'Excessive'**
  String get map_soil_status_excessive;

  /// No description provided for @map_ec_label.
  ///
  /// In en, this message translates to:
  /// **'Electrical Conductivity'**
  String get map_ec_label;

  /// No description provided for @map_ec_very_low.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get map_ec_very_low;

  /// No description provided for @map_ec_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get map_ec_high;

  /// No description provided for @map_ec_too_high.
  ///
  /// In en, this message translates to:
  /// **'Too High - Salinity Issue'**
  String get map_ec_too_high;

  /// No description provided for @map_temp_cool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get map_temp_cool;

  /// No description provided for @map_temp_warm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get map_temp_warm;

  /// No description provided for @map_temp_too_hot.
  ///
  /// In en, this message translates to:
  /// **'Too Hot'**
  String get map_temp_too_hot;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to your plantation'**
  String get login_subtitle;

  /// No description provided for @login_app_tagline.
  ///
  /// In en, this message translates to:
  /// **'Tea Plantation Management'**
  String get login_app_tagline;

  /// No description provided for @login_username_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get login_username_hint;

  /// No description provided for @login_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get login_password_hint;

  /// No description provided for @login_password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get login_password_required;

  /// No description provided for @login_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_forgot_password;

  /// No description provided for @login_sign_in_pin.
  ///
  /// In en, this message translates to:
  /// **'Sign In with PIN'**
  String get login_sign_in_pin;

  /// No description provided for @login_sign_in_biometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Biometrics'**
  String get login_sign_in_biometrics;

  /// No description provided for @login_or_continue_with.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get login_or_continue_with;

  /// No description provided for @login_continue_google.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get login_continue_google;

  /// No description provided for @login_no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get login_no_account;

  /// No description provided for @login_create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get login_create_account;

  /// No description provided for @login_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact Support'**
  String get login_contact_support;

  /// No description provided for @login_demo_credentials.
  ///
  /// In en, this message translates to:
  /// **'Demo Credentials'**
  String get login_demo_credentials;

  /// No description provided for @login_pin_title.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to Login'**
  String get login_pin_title;

  /// No description provided for @login_pin_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_pin_button;

  /// No description provided for @login_pin_min_digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get login_pin_min_digits;

  /// No description provided for @login_pin_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN code'**
  String get login_pin_invalid;

  /// No description provided for @login_pin_failed.
  ///
  /// In en, this message translates to:
  /// **'PIN login failed. Please try again.'**
  String get login_pin_failed;

  /// No description provided for @login_biometric_failed_auth.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get login_biometric_failed_auth;

  /// No description provided for @login_biometric_failed.
  ///
  /// In en, this message translates to:
  /// **'Biometric login failed. Please try again.'**
  String get login_biometric_failed;

  /// No description provided for @login_google_failed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get login_google_failed;

  /// No description provided for @login_google_failed_retry.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed. Please try again.'**
  String get login_google_failed_retry;

  /// No description provided for @login_error_generic.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get login_error_generic;

  /// No description provided for @forgot_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_title;

  /// No description provided for @forgot_description.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! It happens. Please enter the email address associated with your account.'**
  String get forgot_description;

  /// No description provided for @forgot_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get forgot_email_label;

  /// No description provided for @forgot_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get forgot_email_hint;

  /// No description provided for @forgot_email_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgot_email_required;

  /// No description provided for @forgot_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get forgot_email_invalid;

  /// No description provided for @forgot_send_button.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgot_send_button;

  /// No description provided for @forgot_back_to_login.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgot_back_to_login;

  /// No description provided for @forgot_success_title.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get forgot_success_title;

  /// No description provided for @forgot_success_desc.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset link to:'**
  String get forgot_success_desc;

  /// No description provided for @forgot_step_open_email.
  ///
  /// In en, this message translates to:
  /// **'Open the email we sent you'**
  String get forgot_step_open_email;

  /// No description provided for @forgot_step_click_link.
  ///
  /// In en, this message translates to:
  /// **'Click on the reset password link'**
  String get forgot_step_click_link;

  /// No description provided for @forgot_step_new_password.
  ///
  /// In en, this message translates to:
  /// **'Create your new password'**
  String get forgot_step_new_password;

  /// No description provided for @forgot_resend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Resend'**
  String get forgot_resend;

  /// No description provided for @forgot_resend_success.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent again!'**
  String get forgot_resend_success;

  /// No description provided for @register_title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register_title;

  /// No description provided for @register_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join iTeaGrow to manage your tea plantation'**
  String get register_subtitle;

  /// No description provided for @register_full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get register_full_name;

  /// No description provided for @register_full_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get register_full_name_required;

  /// No description provided for @register_full_name_min.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get register_full_name_min;

  /// No description provided for @register_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get register_username;

  /// No description provided for @register_username_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get register_username_required;

  /// No description provided for @register_username_min.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get register_username_min;

  /// No description provided for @register_username_invalid.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get register_username_invalid;

  /// No description provided for @register_email_optional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get register_email_optional;

  /// No description provided for @register_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get register_email_invalid;

  /// No description provided for @register_phone_optional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get register_phone_optional;

  /// No description provided for @register_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get register_password;

  /// No description provided for @register_password_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get register_password_required;

  /// No description provided for @register_password_min.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get register_password_min;

  /// No description provided for @register_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get register_confirm_password;

  /// No description provided for @register_confirm_required.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get register_confirm_required;

  /// No description provided for @register_passwords_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get register_passwords_match;

  /// No description provided for @register_accept_terms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get register_accept_terms;

  /// No description provided for @register_terms_link.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get register_terms_link;

  /// No description provided for @register_accept_terms_error.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get register_accept_terms_error;

  /// No description provided for @register_button.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register_button;

  /// No description provided for @register_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get register_failed;

  /// No description provided for @register_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get register_have_account;

  /// No description provided for @register_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get register_sign_in;

  /// No description provided for @login_welcome_back_heading.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get login_welcome_back_heading;

  /// No description provided for @settings_profile_sub.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile information'**
  String get settings_profile_sub;

  /// No description provided for @settings_logout_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get settings_logout_sub;

  /// No description provided for @settings_section_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_section_account;

  /// No description provided for @settings_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settings_change_password;

  /// No description provided for @settings_change_password_sub.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get settings_change_password_sub;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_security_sub.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication, login history'**
  String get settings_security_sub;

  /// No description provided for @settings_biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get settings_biometric;

  /// No description provided for @settings_biometric_enabled_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with fingerprint or face'**
  String get settings_biometric_enabled_sub;

  /// No description provided for @settings_biometric_disabled_sub.
  ///
  /// In en, this message translates to:
  /// **'Enable fingerprint or face login'**
  String get settings_biometric_disabled_sub;

  /// No description provided for @settings_pin.
  ///
  /// In en, this message translates to:
  /// **'PIN Login'**
  String get settings_pin;

  /// No description provided for @settings_pin_enabled_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a 4-8 digit PIN'**
  String get settings_pin_enabled_sub;

  /// No description provided for @settings_pin_disabled_sub.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN login'**
  String get settings_pin_disabled_sub;

  /// No description provided for @settings_change_pin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settings_change_pin;

  /// No description provided for @settings_change_pin_sub.
  ///
  /// In en, this message translates to:
  /// **'Update your current PIN code'**
  String get settings_change_pin_sub;

  /// No description provided for @settings_section_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_section_preferences;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_notifications_sub.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts and updates'**
  String get settings_notifications_sub;

  /// No description provided for @settings_dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_dark_mode;

  /// No description provided for @settings_dark_mode_sub.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get settings_dark_mode_sub;

  /// No description provided for @settings_dark_mode_soon.
  ///
  /// In en, this message translates to:
  /// **'Dark mode coming soon!'**
  String get settings_dark_mode_soon;

  /// No description provided for @settings_units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settings_units;

  /// No description provided for @settings_section_connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get settings_section_connectivity;

  /// No description provided for @settings_iot_devices.
  ///
  /// In en, this message translates to:
  /// **'IoT Devices'**
  String get settings_iot_devices;

  /// No description provided for @settings_iot_devices_sub.
  ///
  /// In en, this message translates to:
  /// **'Manage connected sensors'**
  String get settings_iot_devices_sub;

  /// No description provided for @settings_auto_sync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get settings_auto_sync;

  /// No description provided for @settings_auto_sync_sub.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync data with cloud'**
  String get settings_auto_sync_sub;

  /// No description provided for @settings_network.
  ///
  /// In en, this message translates to:
  /// **'Network Settings'**
  String get settings_network;

  /// No description provided for @settings_network_sub.
  ///
  /// In en, this message translates to:
  /// **'Configure WiFi and data usage'**
  String get settings_network_sub;

  /// No description provided for @settings_network_soon.
  ///
  /// In en, this message translates to:
  /// **'Network settings coming soon!'**
  String get settings_network_soon;

  /// No description provided for @settings_section_app.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settings_section_app;

  /// No description provided for @settings_haptic.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get settings_haptic;

  /// No description provided for @settings_haptic_sub.
  ///
  /// In en, this message translates to:
  /// **'Vibration on interactions'**
  String get settings_haptic_sub;

  /// No description provided for @settings_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settings_storage;

  /// No description provided for @settings_storage_sub.
  ///
  /// In en, this message translates to:
  /// **'Manage cached data and downloads'**
  String get settings_storage_sub;

  /// No description provided for @settings_export.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settings_export;

  /// No description provided for @settings_export_sub.
  ///
  /// In en, this message translates to:
  /// **'Download your plantation data'**
  String get settings_export_sub;

  /// No description provided for @settings_export_soon.
  ///
  /// In en, this message translates to:
  /// **'Export feature coming soon!'**
  String get settings_export_soon;

  /// No description provided for @settings_section_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settings_section_support;

  /// No description provided for @settings_help.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settings_help;

  /// No description provided for @settings_help_sub.
  ///
  /// In en, this message translates to:
  /// **'FAQs and guides'**
  String get settings_help_sub;

  /// No description provided for @settings_feedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settings_feedback;

  /// No description provided for @settings_feedback_sub.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app'**
  String get settings_feedback_sub;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_about_sub.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settings_about_sub;

  /// No description provided for @settings_section_danger.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get settings_section_danger;

  /// No description provided for @settings_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settings_delete_account;

  /// No description provided for @settings_delete_account_sub.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get settings_delete_account_sub;

  /// No description provided for @settings_dialog_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settings_dialog_change_password;

  /// No description provided for @settings_dialog_current_password.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get settings_dialog_current_password;

  /// No description provided for @settings_dialog_new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get settings_dialog_new_password;

  /// No description provided for @settings_dialog_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get settings_dialog_confirm_password;

  /// No description provided for @settings_dialog_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settings_dialog_change;

  /// No description provided for @settings_dialog_password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get settings_dialog_password_changed;

  /// No description provided for @settings_dialog_clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settings_dialog_clear_cache;

  /// No description provided for @settings_dialog_clear_cache_desc.
  ///
  /// In en, this message translates to:
  /// **'This will clear all cached data and downloaded files. This action cannot be undone.'**
  String get settings_dialog_clear_cache_desc;

  /// No description provided for @settings_dialog_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_dialog_clear;

  /// No description provided for @settings_cache_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully!'**
  String get settings_cache_cleared;

  /// No description provided for @settings_dialog_feedback_hint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think...'**
  String get settings_dialog_feedback_hint;

  /// No description provided for @settings_dialog_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get settings_dialog_send;

  /// No description provided for @settings_feedback_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get settings_feedback_thanks;

  /// No description provided for @settings_dialog_about_version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settings_dialog_about_version;

  /// No description provided for @settings_dialog_about_desc.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Tea Plantation Management System'**
  String get settings_dialog_about_desc;

  /// No description provided for @settings_dialog_about_copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 iTeaGrow Research Project'**
  String get settings_dialog_about_copyright;

  /// No description provided for @settings_dialog_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settings_dialog_close;

  /// No description provided for @settings_dialog_biometric.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login'**
  String get settings_dialog_biometric;

  /// No description provided for @settings_dialog_biometric_desc.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to enable biometric login.'**
  String get settings_dialog_biometric_desc;

  /// No description provided for @settings_dialog_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settings_dialog_password;

  /// No description provided for @settings_dialog_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get settings_dialog_enable;

  /// No description provided for @settings_biometric_enabled_msg.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled!'**
  String get settings_biometric_enabled_msg;

  /// No description provided for @settings_biometric_disabled_msg.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get settings_biometric_disabled_msg;

  /// No description provided for @settings_biometric_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable biometric login'**
  String get settings_biometric_login_failed;

  /// No description provided for @settings_dialog_logout_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settings_dialog_logout_desc;

  /// No description provided for @settings_logout_btn.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settings_logout_btn;

  /// No description provided for @settings_dialog_delete_desc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data. This action cannot be undone.'**
  String get settings_dialog_delete_desc;

  /// No description provided for @settings_delete_btn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settings_delete_btn;

  /// No description provided for @settings_delete_demo_msg.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is disabled in demo mode.'**
  String get settings_delete_demo_msg;

  /// No description provided for @settings_dialog_change_pin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settings_dialog_change_pin;

  /// No description provided for @settings_dialog_change_pin_desc.
  ///
  /// In en, this message translates to:
  /// **'Enter your current account password and a new PIN.'**
  String get settings_dialog_change_pin_desc;

  /// No description provided for @settings_dialog_account_password.
  ///
  /// In en, this message translates to:
  /// **'Current Account Password'**
  String get settings_dialog_account_password;

  /// No description provided for @settings_dialog_new_pin.
  ///
  /// In en, this message translates to:
  /// **'New PIN Code'**
  String get settings_dialog_new_pin;

  /// No description provided for @settings_changing_pin_btn.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settings_changing_pin_btn;

  /// No description provided for @settings_pin_changed_msg.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully!'**
  String get settings_pin_changed_msg;

  /// No description provided for @settings_pin_change_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change PIN'**
  String get settings_pin_change_failed;

  /// No description provided for @settings_dialog_enable_pin.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN Login'**
  String get settings_dialog_enable_pin;

  /// No description provided for @settings_dialog_enable_pin_desc.
  ///
  /// In en, this message translates to:
  /// **'Set a 4 to 8 digit PIN Code for quick login.'**
  String get settings_dialog_enable_pin_desc;

  /// No description provided for @settings_pin_helper_text.
  ///
  /// In en, this message translates to:
  /// **'Required to securely save your PIN'**
  String get settings_pin_helper_text;

  /// No description provided for @settings_pin_login_enabled_msg.
  ///
  /// In en, this message translates to:
  /// **'PIN login enabled!'**
  String get settings_pin_login_enabled_msg;

  /// No description provided for @settings_pin_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable PIN login'**
  String get settings_pin_login_failed;

  /// No description provided for @settings_pin_login_disabled_msg.
  ///
  /// In en, this message translates to:
  /// **'PIN login disabled'**
  String get settings_pin_login_disabled_msg;

  /// No description provided for @settings_pin_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a PIN'**
  String get settings_pin_required;

  /// No description provided for @settings_pin_too_short.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get settings_pin_too_short;

  /// No description provided for @settings_pin_too_long.
  ///
  /// In en, this message translates to:
  /// **'PIN must be max 8 digits'**
  String get settings_pin_too_long;

  /// No description provided for @settings_pin_numbers_only.
  ///
  /// In en, this message translates to:
  /// **'PIN must be numbers only'**
  String get settings_pin_numbers_only;

  /// No description provided for @settings_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get settings_required;

  /// No description provided for @dashboard_good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get dashboard_good_morning;

  /// No description provided for @dashboard_good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get dashboard_good_afternoon;

  /// No description provided for @dashboard_good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get dashboard_good_evening;

  /// No description provided for @dashboard_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to iTeaGrow'**
  String get dashboard_welcome_title;

  /// No description provided for @dashboard_welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your intelligent companion for optimized tea cultivation. Explore analytics, get AI-driven insights.'**
  String get dashboard_welcome_subtitle;

  /// No description provided for @dashboard_system_online.
  ///
  /// In en, this message translates to:
  /// **'System Online'**
  String get dashboard_system_online;

  /// No description provided for @dashboard_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboard_see_all;

  /// No description provided for @dashboard_view_all.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboard_view_all;

  /// No description provided for @dashboard_no_activity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashboard_no_activity;

  /// No description provided for @dashboard_recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboard_recent_activity;

  /// No description provided for @dashboard_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search features, pages, tools...'**
  String get dashboard_search_hint;

  /// No description provided for @dashboard_all_clear.
  ///
  /// In en, this message translates to:
  /// **'All clear — no active alerts'**
  String get dashboard_all_clear;

  /// No description provided for @dashboard_disease_scan.
  ///
  /// In en, this message translates to:
  /// **'Disease Scan'**
  String get dashboard_disease_scan;

  /// No description provided for @dashboard_disease_scan_sub.
  ///
  /// In en, this message translates to:
  /// **'AI-powered detection'**
  String get dashboard_disease_scan_sub;

  /// No description provided for @dashboard_leaf_maturity.
  ///
  /// In en, this message translates to:
  /// **'Leaf Maturity'**
  String get dashboard_leaf_maturity;

  /// No description provided for @dashboard_leaf_maturity_sub.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get dashboard_leaf_maturity_sub;

  /// No description provided for @dashboard_soil_analysis.
  ///
  /// In en, this message translates to:
  /// **'Soil Analysis'**
  String get dashboard_soil_analysis;

  /// No description provided for @dashboard_soil_analysis_sub.
  ///
  /// In en, this message translates to:
  /// **'NPK nutrients'**
  String get dashboard_soil_analysis_sub;

  /// No description provided for @dashboard_iot_sensors.
  ///
  /// In en, this message translates to:
  /// **'IoT Sensors'**
  String get dashboard_iot_sensors;

  /// No description provided for @dashboard_iot_sensors_sub.
  ///
  /// In en, this message translates to:
  /// **'Real-time data'**
  String get dashboard_iot_sensors_sub;

  /// No description provided for @dashboard_powder_grading.
  ///
  /// In en, this message translates to:
  /// **'Powder Grading'**
  String get dashboard_powder_grading;

  /// No description provided for @dashboard_powder_grading_sub.
  ///
  /// In en, this message translates to:
  /// **'Quality grade'**
  String get dashboard_powder_grading_sub;

  /// No description provided for @dashboard_yield_forecast.
  ///
  /// In en, this message translates to:
  /// **'Yield Forecast'**
  String get dashboard_yield_forecast;

  /// No description provided for @dashboard_yield_forecast_sub.
  ///
  /// In en, this message translates to:
  /// **'Predict harvest'**
  String get dashboard_yield_forecast_sub;

  /// No description provided for @dashboard_my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get dashboard_my_profile;

  /// No description provided for @tour_retake.
  ///
  /// In en, this message translates to:
  /// **'Re-take Tour'**
  String get tour_retake;

  /// No description provided for @dashboard_log_out.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get dashboard_log_out;

  /// No description provided for @dashboard_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get dashboard_map;

  /// No description provided for @dashboard_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboard_profile;

  /// No description provided for @dashboard_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard_home;

  /// No description provided for @dashboard_manager_estate_label.
  ///
  /// In en, this message translates to:
  /// **'Estate Manager,'**
  String get dashboard_manager_estate_label;

  /// No description provided for @dashboard_manager_role.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get dashboard_manager_role;

  /// No description provided for @dashboard_manager_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Managers Dashboard'**
  String get dashboard_manager_welcome;

  /// No description provided for @dashboard_manager_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your centralized command center for plantation oversight. Manage teams, monitor field health, and review analytics.'**
  String get dashboard_manager_subtitle;

  /// No description provided for @dashboard_section_field.
  ///
  /// In en, this message translates to:
  /// **'Field & Plant Management'**
  String get dashboard_section_field;

  /// No description provided for @dashboard_section_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Health'**
  String get dashboard_section_analytics;

  /// No description provided for @dashboard_section_market.
  ///
  /// In en, this message translates to:
  /// **'Market & Administration'**
  String get dashboard_section_market;

  /// No description provided for @dashboard_soil_test.
  ///
  /// In en, this message translates to:
  /// **'Soil Test'**
  String get dashboard_soil_test;

  /// No description provided for @dashboard_soil_test_sub.
  ///
  /// In en, this message translates to:
  /// **'Nutrient check'**
  String get dashboard_soil_test_sub;

  /// No description provided for @dashboard_tag_maturity.
  ///
  /// In en, this message translates to:
  /// **'MATURITY'**
  String get dashboard_tag_maturity;

  /// No description provided for @dashboard_tag_soil.
  ///
  /// In en, this message translates to:
  /// **'SOIL'**
  String get dashboard_tag_soil;

  /// No description provided for @dashboard_tag_live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get dashboard_tag_live;

  /// No description provided for @dashboard_tag_diagnosis.
  ///
  /// In en, this message translates to:
  /// **'DIAGNOSIS'**
  String get dashboard_tag_diagnosis;

  /// No description provided for @dashboard_tag_grading.
  ///
  /// In en, this message translates to:
  /// **'GRADING'**
  String get dashboard_tag_grading;

  /// No description provided for @dashboard_tag_analysis.
  ///
  /// In en, this message translates to:
  /// **'ANALYSIS'**
  String get dashboard_tag_analysis;

  /// No description provided for @dashboard_tag_admin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get dashboard_tag_admin;

  /// No description provided for @dashboard_disease_plant_sub.
  ///
  /// In en, this message translates to:
  /// **'Plant health'**
  String get dashboard_disease_plant_sub;

  /// No description provided for @dashboard_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get dashboard_quality;

  /// No description provided for @dashboard_quality_sub.
  ///
  /// In en, this message translates to:
  /// **'Powder grade'**
  String get dashboard_quality_sub;

  /// No description provided for @dashboard_yield_predict.
  ///
  /// In en, this message translates to:
  /// **'Yield Predict'**
  String get dashboard_yield_predict;

  /// No description provided for @dashboard_yield_predict_sub.
  ///
  /// In en, this message translates to:
  /// **'Block progress'**
  String get dashboard_yield_predict_sub;

  /// No description provided for @dashboard_market_prices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get dashboard_market_prices;

  /// No description provided for @dashboard_market_prices_sub.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get dashboard_market_prices_sub;

  /// No description provided for @dashboard_market_admin.
  ///
  /// In en, this message translates to:
  /// **'Market Admin'**
  String get dashboard_market_admin;

  /// No description provided for @dashboard_market_admin_sub.
  ///
  /// In en, this message translates to:
  /// **'Update Rates'**
  String get dashboard_market_admin_sub;

  /// No description provided for @dashboard_drawer_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_drawer_dashboard;

  /// No description provided for @dashboard_drawer_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get dashboard_drawer_help;

  /// No description provided for @dashboard_drawer_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get dashboard_drawer_logout;

  /// No description provided for @contact_get_in_touch.
  ///
  /// In en, this message translates to:
  /// **'Get in Touch'**
  String get contact_get_in_touch;

  /// No description provided for @contact_description.
  ///
  /// In en, this message translates to:
  /// **'If you face any issues or have questions regarding iTeaGrow, feel free to reach out to our team.'**
  String get contact_description;

  /// No description provided for @contact_email_support.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get contact_email_support;

  /// No description provided for @contact_email_support_address.
  ///
  /// In en, this message translates to:
  /// **'admin.iteagrow@gmail.com'**
  String get contact_email_support_address;

  /// No description provided for @contact_our_locations.
  ///
  /// In en, this message translates to:
  /// **'Our Locations'**
  String get contact_our_locations;

  /// No description provided for @contact_location_research.
  ///
  /// In en, this message translates to:
  /// **'Location (Research)'**
  String get contact_location_research;

  /// No description provided for @contact_location_research_address.
  ///
  /// In en, this message translates to:
  /// **'Hatton, Sri Lanka'**
  String get contact_location_research_address;

  /// No description provided for @contact_location_academic.
  ///
  /// In en, this message translates to:
  /// **'Location (Academic Site)'**
  String get contact_location_academic;

  /// No description provided for @contact_location_academic_address.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka Institute of Information Technology, SLIIT Malabe Campus, New Kandy Rd, Malabe 10115'**
  String get contact_location_academic_address;

  /// No description provided for @contact_footer.
  ///
  /// In en, this message translates to:
  /// **'© 2026 iTeaGrow Team'**
  String get contact_footer;

  /// No description provided for @contact_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your message or feedback...'**
  String get contact_message_hint;

  /// No description provided for @contact_message_sent.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully!'**
  String get contact_message_sent;

  /// No description provided for @contact_phone_value.
  ///
  /// In en, this message translates to:
  /// **'+94 XX XXX XXXX'**
  String get contact_phone_value;

  /// No description provided for @contact_address_value.
  ///
  /// In en, this message translates to:
  /// **'Tea Research Institute\nTalawakelle, Sri Lanka'**
  String get contact_address_value;

  /// No description provided for @contact_email_value.
  ///
  /// In en, this message translates to:
  /// **'info@iteagrow.lk'**
  String get contact_email_value;

  /// No description provided for @profile_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get profile_role_admin;

  /// No description provided for @profile_role_manager.
  ///
  /// In en, this message translates to:
  /// **'Plantation Manager'**
  String get profile_role_manager;

  /// No description provided for @profile_role_farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get profile_role_farmer;

  /// No description provided for @profile_role_default.
  ///
  /// In en, this message translates to:
  /// **'Field Officer'**
  String get profile_role_default;

  /// No description provided for @profile_full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profile_full_name;

  /// No description provided for @profile_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_name_label;

  /// No description provided for @profile_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profile_save_changes;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profile_updated;

  /// No description provided for @profile_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profile_update_failed;

  /// No description provided for @yield_results_section_forecast.
  ///
  /// In en, this message translates to:
  /// **'Yield Forecast'**
  String get yield_results_section_forecast;

  /// No description provided for @yield_results_daily_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily Breakdown'**
  String get yield_results_daily_breakdown;

  /// No description provided for @yield_results_advanced_analysis.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analysis'**
  String get yield_results_advanced_analysis;

  /// No description provided for @yield_results_section_temp.
  ///
  /// In en, this message translates to:
  /// **'Yield Forecast vs Temperature'**
  String get yield_results_section_temp;

  /// No description provided for @yield_results_section_rain.
  ///
  /// In en, this message translates to:
  /// **'Rainfall Impact on Yield'**
  String get yield_results_section_rain;

  /// No description provided for @yield_results_section_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Analysis'**
  String get yield_results_section_efficiency;

  /// No description provided for @yield_results_best_harvest.
  ///
  /// In en, this message translates to:
  /// **'Best Harvest Day'**
  String get yield_results_best_harvest;

  /// No description provided for @yield_results_avg_daily.
  ///
  /// In en, this message translates to:
  /// **'Avg. Daily'**
  String get yield_results_avg_daily;

  /// No description provided for @yield_results_highest_yield.
  ///
  /// In en, this message translates to:
  /// **'Highest Yield'**
  String get yield_results_highest_yield;

  /// No description provided for @yield_results_prediction.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get yield_results_prediction;

  /// No description provided for @yield_results_weather_temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get yield_results_weather_temp;

  /// No description provided for @yield_results_weather_humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get yield_results_weather_humidity;

  /// No description provided for @yield_results_weather_rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get yield_results_weather_rain;

  /// No description provided for @yield_results_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get yield_results_today;

  /// No description provided for @yield_results_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get yield_results_tomorrow;

  /// No description provided for @yield_results_outlier_low.
  ///
  /// In en, this message translates to:
  /// **'Avg. daily yield ({avg} kg) is unusually low — verify your inputs.'**
  String yield_results_outlier_low(String avg);

  /// No description provided for @yield_results_outlier_high.
  ///
  /// In en, this message translates to:
  /// **'Avg. daily yield ({avg} kg) is unusually high — verify your inputs.'**
  String yield_results_outlier_high(String avg);

  /// No description provided for @yield_results_outlier_ha.
  ///
  /// In en, this message translates to:
  /// **'Yield/ha ({yieldPerHa} kg/ha/day) is very high — please verify field size and crop data.'**
  String yield_results_outlier_ha(String yieldPerHa);

  /// No description provided for @analytics_dashboard_label.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analytics_dashboard_label;

  /// No description provided for @analytics_ready_desc.
  ///
  /// In en, this message translates to:
  /// **'Ready for data visualization and trends'**
  String get analytics_ready_desc;

  /// No description provided for @chart_no_trend_data.
  ///
  /// In en, this message translates to:
  /// **'No trend data available'**
  String get chart_no_trend_data;

  /// No description provided for @chart_no_trend_grade.
  ///
  /// In en, this message translates to:
  /// **'No trend data for selected grade'**
  String get chart_no_trend_grade;

  /// No description provided for @chart_radar_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get chart_radar_color;

  /// No description provided for @chart_radar_aroma.
  ///
  /// In en, this message translates to:
  /// **'Aroma'**
  String get chart_radar_aroma;

  /// No description provided for @chart_radar_freshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get chart_radar_freshness;

  /// No description provided for @chart_your_batch.
  ///
  /// In en, this message translates to:
  /// **'Your Batch'**
  String get chart_your_batch;

  /// No description provided for @chart_premium_target.
  ///
  /// In en, this message translates to:
  /// **'Premium Target'**
  String get chart_premium_target;
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
