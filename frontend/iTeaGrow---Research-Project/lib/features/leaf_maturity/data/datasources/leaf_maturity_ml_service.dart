// Conditional export: native (tflite) on mobile/desktop, stub on web.
export 'leaf_maturity_ml_service_native.dart'
    if (dart.library.html) 'leaf_maturity_ml_service_web.dart';
