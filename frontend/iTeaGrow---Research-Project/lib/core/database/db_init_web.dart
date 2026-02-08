import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void initializeDatabaseFactory() {
  debugPrint('Web platform detected. Initializing databaseFactoryFfiWeb...');
  databaseFactory = databaseFactoryFfiWeb;
}
