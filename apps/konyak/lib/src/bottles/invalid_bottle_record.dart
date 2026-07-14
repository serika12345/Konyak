enum InvalidBottleCode { invalidProgramProfiles, invalidBottleMetadata }

enum InvalidBottleRecoveryAction { discardInvalidProfiles }

final class InvalidBottleRecord {
  InvalidBottleRecord({
    required this.storageId,
    required this.path,
    required this.code,
    required this.message,
    required Iterable<InvalidBottleRecoveryAction> recoveryActions,
  }) : recoveryActions = List.unmodifiable(recoveryActions);

  final String storageId;
  final String path;
  final InvalidBottleCode code;
  final String message;
  final List<InvalidBottleRecoveryAction> recoveryActions;

  bool get canDiscardInvalidProfiles => recoveryActions.contains(
    InvalidBottleRecoveryAction.discardInvalidProfiles,
  );
}
