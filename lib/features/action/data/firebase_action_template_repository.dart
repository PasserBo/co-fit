import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity/action_template_card.dart';
import 'action_template_repository.dart';

class FirebaseActionTemplateRepository implements ActionTemplateRepository {
  FirebaseActionTemplateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<ActionTemplateCard>> getTemplateCards() async {
    final snapshot = await _firestore.collection('card_templates').get();
    if (snapshot.docs.isEmpty) {
      throw StateError('未配置模板卡');
    }

    return snapshot.docs.map(_toTemplateCard).toList(growable: false);
  }

  ActionTemplateCard _toTemplateCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final defaultDurationSecValue = data['defaultDurationSec'];

    return ActionTemplateCard(
      id: doc.id,
      name: _readRequiredString(data, 'name', doc.id),
      type: _readRequiredString(data, 'type', doc.id),
      ablyActionId: _readRequiredString(data, 'ablyActionId', doc.id),
      defaultDurationSec: _readRequiredInt(
        defaultDurationSecValue,
        fieldName: 'defaultDurationSec',
        templateId: doc.id,
      ),
      intensityBaseline: _readMap(data['intensityBaseline']),
    );
  }

  String _readRequiredString(
    Map<String, dynamic> data,
    String fieldName,
    String templateId,
  ) {
    final value = data[fieldName];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw StateError('模板卡 $templateId 缺少有效字段: $fieldName');
  }

  int _readRequiredInt(
    Object? value, {
    required String fieldName,
    required String templateId,
  }) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    throw StateError('模板卡 $templateId 缺少有效字段: $fieldName');
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }
}
