import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'action_template_repository.dart';
import 'firebase_action_template_repository.dart';

final firebaseActionTemplateRepositoryProvider =
    Provider<FirebaseActionTemplateRepository>((ref) {
      return FirebaseActionTemplateRepository();
    });

final actionTemplateRepositoryProvider = Provider<ActionTemplateRepository>((
  ref,
) {
  return ref.watch(firebaseActionTemplateRepositoryProvider);
});
