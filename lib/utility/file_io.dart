import 'dart:io';

import 'package:firestore_crud_util/utility/shared_prefs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FileIO {
  static Directory? _directory;

  static Future<void> writeToFile({
    required String fileName,
    required String data,
  }) async {
    if (kIsWeb) {
      SharedPrefs.setString(key: fileName, value: data);
    } else {
      _directory ??= await getApplicationDocumentsDirectory();
      final file = File('${_directory?.path}/firestore_utils/$fileName');
      await file.create(recursive: true);
      file.writeAsString(data);
    }
  }

  static Future<String> readFromFile({required String fileName}) async {
    if (kIsWeb) {
      return await SharedPrefs.getString(key: fileName) ?? "";
    } else {
      _directory ??= await getApplicationDocumentsDirectory();
      final file = File('${_directory?.path}/firestore_utils/$fileName');
      return file.readAsString();
    }
  }
}
