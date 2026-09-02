import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/custom_card_repository.dart';
import '../domain/entity/action_source.dart';
import '../domain/entity/action_template_card.dart';
import '../domain/entity/action_type.dart';

class FirebaseCustomCardRepository implements CustomCardRepository {
  FirebaseCustomCardRepository({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _cardsRef {
    return _firestore.collection('users').doc(_userId).collection('cards');
  }

  @override
  Future<List<ActionTemplateCard>> getCustomCards() async {
    final snapshot = await _cardsRef.orderBy('createdAt').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final rawType = (data['type'] ?? '').toString();
      return ActionTemplateCard(
        id: doc.id,
        name: (data['name'] ?? '').toString(),
        type: ActionType.fromRaw(rawType),
        rawType: rawType,
        source: ActionSource.custom,
        ablyActionId: (data['ablyActionId'] ?? rawType).toString(),
        defaultDurationSec: _asInt(data['defaultDurationSec']),
        intensityBaseline: _asMap(data['intensityBaseline']),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> createCard(ActionTemplateCard card) {
    return _cardsRef.doc(card.id).set({
      'cardId': card.id,
      'name': card.name,
      'type': card.rawType,
      'ablyActionId': card.ablyActionId,
      'defaultDurationSec': card.defaultDurationSec,
      'intensityBaseline': card.intensityBaseline,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCard(String cardId) {
    return _cardsRef.doc(cardId).delete();
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }
}
