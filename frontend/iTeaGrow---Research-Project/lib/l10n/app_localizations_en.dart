// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'iTeaGrow';

  @override
  String get appTagline => 'AI-IoT Tea Monitoring System';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_dashboard => 'Dashboard';

  @override
  String get nav_leaf_maturity => 'Leaf Maturity';

  @override
  String get nav_disease => 'Disease Detection';

  @override
  String get nav_fertilization => 'Fertilization';

  @override
  String get nav_powder_grading => 'Powder Grading';

  @override
  String get nav_iot => 'IoT Devices';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_about => 'About Us';

  @override
  String get nav_contact => 'Contact Us';

  @override
  String get landing_welcome => 'Welcome to iTeaGrow';

  @override
  String get landing_description =>
      'AI-powered IoT system for tea leaf monitoring, fertilization management, and powder grading';

  @override
  String get landing_get_started => 'Get Started';

  @override
  String get landing_learn_more => 'Learn More';

  @override
  String get about_title => 'About iTeaGrow';

  @override
  String get about_description =>
      'iTeaGrow is a research project focused on developing an AI-IoT decision support system for tea cultivation in Sri Lanka. The system combines machine learning, IoT sensors, and mobile technology to help farmers optimize tea leaf quality, fertilization, and market value.';

  @override
  String get about_features => 'Key Features';

  @override
  String get about_feature_1 => 'AI-powered leaf maturity detection';

  @override
  String get about_feature_2 => 'Real-time IoT sensor monitoring';

  @override
  String get about_feature_3 => 'Disease detection and prevention';

  @override
  String get about_feature_4 => 'Smart fertilization recommendations';

  @override
  String get about_feature_5 => 'Tea powder quality grading';

  @override
  String get contact_title => 'Contact Us';

  @override
  String get contact_email => 'Email';

  @override
  String get contact_phone => 'Phone';

  @override
  String get contact_address => 'Address';

  @override
  String get contact_feedback => 'Send Feedback';

  @override
  String get contact_message => 'Message';

  @override
  String get contact_send => 'Send';

  @override
  String get login_title => 'Login';

  @override
  String get login_username => 'Username';

  @override
  String get login_password => 'Password';

  @override
  String get login_button => 'Sign In';

  @override
  String get login_language => 'Language';

  @override
  String get login_error => 'Invalid username or password';

  @override
  String get language_english => 'English';

  @override
  String get language_sinhala => 'සිංහල';

  @override
  String get language_tamil => 'தமிழ்';

  @override
  String get role_farmer => 'Farmer';

  @override
  String get role_manager => 'Manager';

  @override
  String get role_admin => 'Administrator';

  @override
  String get dashboard_welcome => 'Welcome';

  @override
  String get dashboard_location => 'Location';

  @override
  String get dashboard_latest_readings => 'Latest Sensor Readings';

  @override
  String get dashboard_alerts => 'Alerts';

  @override
  String get dashboard_quick_actions => 'Quick Actions';

  @override
  String get dashboard_capture_leaf => 'Capture Leaf';

  @override
  String get dashboard_view_recommendations => 'View Recommendations';

  @override
  String get dashboard_analytics => 'Analytics';

  @override
  String get sensor_soil_moisture => 'Soil Moisture';

  @override
  String get sensor_soil_ph => 'Soil pH';

  @override
  String get sensor_nitrogen => 'Nitrogen (N)';

  @override
  String get sensor_phosphorus => 'Phosphorus (P)';

  @override
  String get sensor_potassium => 'Potassium (K)';

  @override
  String get sensor_temperature => 'Temperature';

  @override
  String get sensor_humidity => 'Humidity';

  @override
  String get sensor_last_updated => 'Last Updated';

  @override
  String get sensor_status_optimal => 'Optimal';

  @override
  String get sensor_status_warning => 'Warning';

  @override
  String get sensor_status_critical => 'Critical';

  @override
  String get iot_title => 'IoT Devices';

  @override
  String get iot_connect => 'Connect Device';

  @override
  String get iot_scan => 'Scan for Devices';

  @override
  String get iot_bluetooth => 'Bluetooth';

  @override
  String get iot_wifi => 'Wi-Fi';

  @override
  String get iot_connected => 'Connected';

  @override
  String get iot_disconnected => 'Disconnected';

  @override
  String get iot_connecting => 'Connecting...';

  @override
  String get iot_pair => 'Pair';

  @override
  String get iot_unpair => 'Unpair';

  @override
  String get leaf_title => 'Leaf Maturity Detection';

  @override
  String get leaf_capture => 'Capture Image';

  @override
  String get leaf_from_gallery => 'Choose from Gallery';

  @override
  String get leaf_analyzing => 'Analyzing...';

  @override
  String get leaf_results => 'Results';

  @override
  String get leaf_tender => 'Tender Leaves';

  @override
  String get leaf_mature => 'Mature Leaves';

  @override
  String get leaf_coarser => 'Coarser Leaves';

  @override
  String get leaf_confidence => 'Confidence';

  @override
  String get leaf_yield_prediction => 'Yield Prediction';

  @override
  String get leaf_good_leaf_percentage => 'Good Leaf %';

  @override
  String get leaf_show_heatmap => 'Show Heatmap';

  @override
  String get leaf_recommendation => 'Recommendation';

  @override
  String get disease_title => 'Disease Detection';

  @override
  String get disease_scan => 'Scan for Disease';

  @override
  String get disease_type => 'Disease Type';

  @override
  String get disease_severity => 'Severity';

  @override
  String get disease_low => 'Low';

  @override
  String get disease_medium => 'Medium';

  @override
  String get disease_high => 'High';

  @override
  String get disease_recommendations => 'Recommendations';

  @override
  String get disease_environmental_factors => 'Environmental Factors';

  @override
  String get fertilizer_title => 'Fertilization Management';

  @override
  String get fertilizer_current_levels => 'Current NPK Levels';

  @override
  String get fertilizer_recommendation => 'Recommendation';

  @override
  String get fertilizer_type => 'Fertilizer Type';

  @override
  String get fertilizer_quantity => 'Quantity';

  @override
  String get fertilizer_application => 'Application Method';

  @override
  String get fertilizer_mark_applied => 'Mark as Applied';

  @override
  String get fertilizer_planning => 'Fertilization Planning';

  @override
  String get fertilizer_whatif => 'What-If Simulation';

  @override
  String get powder_title => 'Tea Powder Grading';

  @override
  String get powder_grade => 'Grade';

  @override
  String get powder_quality_score => 'Quality Score';

  @override
  String get powder_market_price => 'Market Price';

  @override
  String get powder_price_trend => 'Price Trend';

  @override
  String get powder_rs_per_kg => 'Rs/kg';

  @override
  String get admin_title => 'System Administration';

  @override
  String get admin_users => 'User Management';

  @override
  String get admin_devices => 'Device Management';

  @override
  String get admin_config => 'System Configuration';

  @override
  String get admin_sync => 'Data Synchronization';

  @override
  String get admin_logs => 'System Logs';

  @override
  String get alert_severity_info => 'Info';

  @override
  String get alert_severity_warning => 'Warning';

  @override
  String get alert_severity_critical => 'Critical';

  @override
  String get alert_mark_read => 'Mark as Read';

  @override
  String get alert_dismiss => 'Dismiss';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_profile => 'Profile';

  @override
  String get settings_logout => 'Logout';

  @override
  String get settings_version => 'Version';
}
