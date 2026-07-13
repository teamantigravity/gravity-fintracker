import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the database factory for desktop operating systems.
/// Mobile platforms use the default sqflite implementation.
Future<void> ensureDatabaseInitialized() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
