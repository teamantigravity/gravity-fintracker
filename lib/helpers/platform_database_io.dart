import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the database factory for desktop operating systems.
/// Mobile platforms use the default sqflite implementation.
Future<void> ensureDatabaseInitialized() async {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
