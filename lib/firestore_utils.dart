import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_crud_util/utility/file_io.dart';
import 'package:firestore_crud_util/utility/logger.dart';
import 'package:firestore_crud_util/utility/shared_prefs.dart';

class FirestoreUtils {
  static Future<T> getData<T>({
    required String collection,
    required String docName,
    required int docVersion,
    required T docData,
  }) async {
    int currentVersion =
        await SharedPrefs.getInt(key: "${docName}Version") ?? 0;

    if (currentVersion < docVersion) {
      logger.i("$docName: Updating prefDocVersion to provided docVersion");
      await SharedPrefs.setInt(key: "${docName}Version", value: docVersion);
      currentVersion = docVersion;
    }

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection(collection)
            .where("docName", isEqualTo: docName)
            .where("version", isGreaterThan: currentVersion)
            .orderBy("version", descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      var latestDoc = querySnapshot.docs.first;
      int latestVersion = latestDoc.get('version') as int;
      if (latestVersion > currentVersion) {
        logger.i("$docName: Newer version $latestVersion found in Firestore");
        await FileIO.writeToFile(
          fileName: docName,
          data: jsonEncode(latestDoc.get('data')),
        );
        await SharedPrefs.setInt(
          key: "${docName}Version",
          value: latestVersion,
        );
        return latestDoc.get('data') as T;
      }
    }

    // No newer version in Firestore, use local data if available and newer
    if (currentVersion > docVersion) {
      try {
        String dataString = await FileIO.readFromFile(fileName: docName);
        logger.i("$docName: Using local data, version $currentVersion");
        return jsonDecode(dataString) as T;
      } catch (e) {
        logger.w("$docName: Local file read failed, falling back to docData");
      }
    }

    logger.i("$docName: Returning provided docData");
    return docData;
  }

  static Stream<T> getDataStream<T>({
    required String collection,
    required String docName,
    required int docVersion,
    required T docData,
  }) async* {
    int currentVersion =
        await SharedPrefs.getInt(key: "${docName}Version") ?? 0;

    // Yield initial data
    T currentData = docData;
    if (currentVersion > docVersion) {
      try {
        String dataString = await FileIO.readFromFile(fileName: docName);
        currentData = jsonDecode(dataString) as T;
        logger.i("$docName: Yielding local data, version $currentVersion");
      } catch (e) {
        logger.w("$docName: Local file read failed, using docData");
        currentVersion = docVersion;
        await SharedPrefs.setInt(
          key: "${docName}Version",
          value: currentVersion,
        );
      }
    } else if (currentVersion < docVersion) {
      currentVersion = docVersion;
      await SharedPrefs.setInt(key: "${docName}Version", value: currentVersion);
    }
    yield currentData;

    // Listen for updates
    await for (QuerySnapshot querySnapshot
        in FirebaseFirestore.instance
            .collection(collection)
            .where("docName", isEqualTo: docName)
            .where("version", isGreaterThan: currentVersion)
            .orderBy("version", descending: true)
            .limit(1)
            .snapshots()) {
      if (querySnapshot.docs.isNotEmpty) {
        var latestDoc = querySnapshot.docs.first;
        int latestVersion = latestDoc.get('version') as int;
        if (latestVersion > currentVersion) {
          logger.i("$docName: New version $latestVersion from Firestore");
          await FileIO.writeToFile(
            fileName: docName,
            data: jsonEncode(latestDoc.get('data')),
          );
          currentVersion = latestVersion;
          await SharedPrefs.setInt(
            key: "${docName}Version",
            value: currentVersion,
          );
          yield latestDoc.get('data') as T;
        }
      }
    }
  }
}
