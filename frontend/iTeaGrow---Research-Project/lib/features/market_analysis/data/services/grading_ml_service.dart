// Conditional export: native (tflite) on mobile/desktop, stub on web.
export 'grading_ml_service_native.dart'
    if (dart.library.html) 'grading_ml_service_web.dart';
