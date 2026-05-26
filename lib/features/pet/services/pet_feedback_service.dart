import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/domain/pet_overlay_event.dart';

class PetFeedbackService {
  PetOverlayEvent createOverlayEvent(
    PetAction action,
    String message, {
    required int moodDelta,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return PetOverlayEvent(
      id: '${createdAt.microsecondsSinceEpoch}_${action.name}',
      action: action,
      message: message,
      createdAt: createdAt,
      moodDelta: moodDelta,
    );
  }
}
