import 'package:cloud_firestore/cloud_firestore.dart';

/// Doc ngay gio tu Firestore (Timestamp) hoac chuoi ISO.
DateTime? readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Timestamp? writeDate(DateTime? value) => value == null ? null : Timestamp.fromDate(value);
