import 'package:todolist/features/pet/domain/pet_action.dart';

class PetOverlayEvent {
  final String id;
  final PetAction action;
  final String message;
  final DateTime createdAt;
  final int moodDelta;

  const PetOverlayEvent({
    required this.id,
    required this.action,
    required this.message,
    required this.createdAt,
    required this.moodDelta,
  });
}
