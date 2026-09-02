import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/action_deck_repository.dart';
import '../domain/entity/action_deck.dart';

/// 牌组云端仓库(A2):
/// - 牌组:users/{uid}/decks/{deckId} `{deckId, name, cardTemplateIds, createdAt, updatedAt}`
/// - activeDeckId:users/{uid} profile 文档的可选键(跨设备同步)
class FirebaseActionDeckRepository implements ActionDeckRepository {
  FirebaseActionDeckRepository({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _decksRef {
    return _firestore.collection('users').doc(_userId).collection('decks');
  }

  DocumentReference<Map<String, dynamic>> get _profileRef {
    return _firestore.collection('users').doc(_userId);
  }

  @override
  Future<List<ActionDeck>> getDecks() async {
    final snapshot = await _decksRef.orderBy('createdAt').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final rawCardIds = data['cardTemplateIds'];
      return ActionDeck(
        id: doc.id,
        name: (data['name'] ?? '').toString(),
        cardIds: rawCardIds is List
            ? rawCardIds.map((id) => id.toString()).toList(growable: false)
            : const <String>[],
      );
    }).toList(growable: false);
  }

  @override
  Future<void> createDeck(ActionDeck deck) {
    return _decksRef.doc(deck.id).set({
      'deckId': deck.id,
      'name': deck.name,
      'cardTemplateIds': deck.cardIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateDeck(ActionDeck deck) {
    // update() 在文档不存在时抛 not-found,符合接口约定。
    return _decksRef.doc(deck.id).update({
      'name': deck.name,
      'cardTemplateIds': deck.cardIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteDeck(String deckId) {
    return _decksRef.doc(deckId).delete();
  }

  @override
  Future<String?> getActiveDeckId() async {
    final snapshot = await _profileRef.get();
    final value = snapshot.data()?['activeDeckId'];
    final id = value?.toString().trim() ?? '';
    return id.isEmpty ? null : id;
  }

  @override
  Future<void> setActiveDeckId(String? deckId) {
    // update 走 profile rules 的 update 分支(整文档形状校验仍成立;
    // activeDeckId 是可选键,删除后 hasOnly 仍通过)。
    return _profileRef.update({
      'activeDeckId': deckId ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
