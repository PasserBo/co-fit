import 'package:cloud_firestore/cloud_firestore.dart';

class RoomVisibility {
  static const String public = 'public';
  static const String unlisted = 'unlisted';
  static const Set<String> allowed = {public, unlisted};
}

class RoomInfoModel {
  RoomInfoModel({
    required this.roomId,
    required this.name,
    required this.description,
    required this.visibility,
    required this.ownerId,
    required this.shareLinkHash,
    required this.shareSalt,
    this.createdAt,
    this.updatedAt,
  });

  final String roomId;
  final String name;
  final String description;
  final String visibility;
  final String ownerId;
  final String shareLinkHash;
  final String shareSalt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toCreateMap() {
    return {
      'roomId': roomId,
      'name': name,
      'description': description,
      'visibility': visibility,
      'ownerId': ownerId,
      'shareLinkHash': shareLinkHash,
      'shareSalt': shareSalt,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'description': description,
      'visibility': visibility,
      'ownerId': ownerId,
      'shareLinkHash': shareLinkHash,
      'shareSalt': shareSalt,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RoomInfoModel.fromMap(Map<String, dynamic> source) {
    return RoomInfoModel(
      roomId: (source['roomId'] ?? '').toString(),
      name: (source['name'] ?? '').toString(),
      description: (source['description'] ?? '').toString(),
      visibility: (source['visibility'] ?? RoomVisibility.unlisted).toString(),
      ownerId: (source['ownerId'] ?? '').toString(),
      shareLinkHash: (source['shareLinkHash'] ?? '').toString(),
      shareSalt: (source['shareSalt'] ?? '').toString(),
      createdAt: _asDateTime(source['createdAt']),
      updatedAt: _asDateTime(source['updatedAt']),
    );
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
