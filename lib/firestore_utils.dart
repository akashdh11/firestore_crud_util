import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_crud_util/utility/file_io.dart';
import 'package:firestore_crud_util/utility/logger.dart';
import 'package:firestore_crud_util/utility/shared_prefs.dart';

class FirestoreUtils {
  static Future<QuerySnapshot> _getCollectionWhereGreaterThan(
    String collection,
    String docName,
    int version,
  ) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where("docName", isEqualTo: docName)
        .where("version", isGreaterThan: version)
        .get();
  }

  static Future<T> getData<T>({
    required String collection,
    required String docName,
    required int docVersion,
    required T docData,
  }) async {
    int prefDocVersion =
        await SharedPrefs.getInt(key: "${docName}Version") ?? 0;

    if (prefDocVersion < docVersion) {
      logger.i(
        "$docName: already latest data data provided, updating SharedPrefs",
      );
      await SharedPrefs.setInt(key: "${docName}Version", value: docVersion);
      prefDocVersion = docVersion;
    }
    QuerySnapshot querySnapshot = await _getCollectionWhereGreaterThan(
      collection,
      docName,
      prefDocVersion,
    );

    if (querySnapshot.docs.isNotEmpty) {
      logger.i("$docName: new version found fetching firestore data");
      loggerNoStack.i(querySnapshot.docs.first.get('data'));
      FileIO.writeToFile(
        fileName: docName,
        data: jsonEncode(querySnapshot.docs.first.get('data')),
      );
      await SharedPrefs.setInt(
        key: "${docName}Version",
        value: querySnapshot.docs.first.get('version') as int,
      );
      try {
        return querySnapshot.docs.first.get('data') as T;
      } catch (e) {
        logger.e("Error", error: e);
        throw Exception(e);
      }
    } else if (querySnapshot.metadata.isFromCache) {
      logger.i(
        "$docName: no data fetched from firestore returning hardcoded data",
      );
      loggerNoStack.i(docData);
      return docData;
    } else if (prefDocVersion == docVersion) {
      logger.i(
        "$docName: already latest data data provided, returning same data",
      );
      loggerNoStack.i(docData);
      return docData;
    } else {
      try {
        String dataString = await FileIO.readFromFile(fileName: docName);
        logger.i("$docName: firestore data fetched from file");
        var data = jsonDecode(dataString);
        loggerNoStack.i(data);
        return data as T;
      } catch (e) {
        await SharedPrefs.setInt(key: "${docName}Version", value: docVersion);
        return getData<T>(
          collection: collection,
          docName: docName,
          docVersion: docVersion,
          docData: docData,
        );
      }
    }
  }

  static Stream<QuerySnapshot> _getCollectionStreamWhereGreaterThan(
    String collection,
    String docName,
    int version,
  ) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where("docName", isEqualTo: docName)
        .where("version", isGreaterThan: version)
        .snapshots();
  }

  static Stream<T> getDataStream<T>({
    required String collection,
    required String docName,
    required int docVersion,
    required T docData,
  }) async* {
    int prefDocVersion =
        await SharedPrefs.getInt(key: "${docName}Version") ?? 0;

    if (prefDocVersion <= docVersion) {
      yield docData;
      logger.i(
        "$docName: returning data provided in stream, checking firebase",
      );
      await SharedPrefs.setInt(key: "${docName}Version", value: docVersion);
      prefDocVersion = docVersion;
    } else {
      try {
        String dataString = await FileIO.readFromFile(fileName: docName);
        logger.i(
          "$docName: returning data from file in stream, checking firebase",
        );
        var data = jsonDecode(dataString);
        loggerNoStack.i(data);
        yield data as T;
      } catch (e) {
        logger.i("$docName: file data corrupted, fetching from firebase");
        await SharedPrefs.setInt(key: "${docName}Version", value: docVersion);
        yield await getData<T>(
          collection: collection,
          docName: docName,
          docVersion: docVersion,
          docData: docData,
        );
      }
    }

    await for (QuerySnapshot querySnapshot
        in _getCollectionStreamWhereGreaterThan(
          collection,
          docName,
          docVersion,
        )) {
      if (querySnapshot.docs.isNotEmpty) {
        logger.i("$docName: firestore data fetched from firebase");
        loggerNoStack.i(querySnapshot.docs.first.get('data'));
        FileIO.writeToFile(
          fileName: docName,
          data: jsonEncode(querySnapshot.docs.first.get('data')),
        );
        await SharedPrefs.setInt(
          key: "${docName}Version",
          value: querySnapshot.docs.first.get('version') as int,
        );
        try {
          yield querySnapshot.docs.first.get('data') as T;
        } catch (e) {
          logger.e("Error", error: e);
          throw Exception(e);
        }
      } else if (querySnapshot.metadata.isFromCache) {
        logger.i(
          "$docName: no data fetched from firebase/cache returning hardcoded data",
        );
        loggerNoStack.i(docData);
        yield docData;
      }
    }
  }
}
