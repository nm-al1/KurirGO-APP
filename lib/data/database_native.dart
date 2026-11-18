import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory courierDatabaseFactory() {
  if ([
    TargetPlatform.windows,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform)) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}
