import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'program_run_models.dart';

part 'program_profile_models.freezed.dart';

const konyakMaxChildProcessRuleArguments = 64;
const konyakMaxChildProcessRulesLength = 65535;
const konyakMaxChildProcessExecutableSuffixLength = 1024;
const konyakMaxChildProcessArgumentLength = 8192;

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class InstallProfileRecord with _$InstallProfileRecord {
  const InstallProfileRecord._();

  factory InstallProfileRecord({
    required String id,
    required String name,
    required int profileVersion,
    required String summary,
    required Iterable<String> platforms,
    required String windowsVersion,
    required String managedProgramPath,
    required Iterable<String> dependencyWinetricksVerbs,
    required CompatibilityProfileRecord compatibilityProfile,
    ProgramRunCompletionPolicy runCompletionPolicy =
        ProgramRunCompletionPolicy.waitForExit,
  }) {
    return InstallProfileRecord._validated(
      id: ProfileId(id),
      name: ProfileName(name),
      profileVersion: ProfileVersion(profileVersion),
      summary: ProfileSummary(summary),
      platforms: platforms.map(RuntimePlatformName.new).toIList(),
      windowsVersion: WindowsVersion(windowsVersion),
      managedProgramPath: ProgramPath(managedProgramPath),
      dependencyWinetricksVerbs: dependencyWinetricksVerbs
          .map(WinetricksVerbId.new)
          .toIList(),
      compatibilityProfile: compatibilityProfile,
      runCompletionPolicy: runCompletionPolicy,
    );
  }

  const factory InstallProfileRecord._validated({
    required ProfileId id,
    required ProfileName name,
    required ProfileVersion profileVersion,
    required ProfileSummary summary,
    required IList<RuntimePlatformName> platforms,
    required WindowsVersion windowsVersion,
    required ProgramPath managedProgramPath,
    required IList<WinetricksVerbId> dependencyWinetricksVerbs,
    required CompatibilityProfileRecord compatibilityProfile,
    required ProgramRunCompletionPolicy runCompletionPolicy,
  }) = _InstallProfileRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class CompatibilityProfileRecord with _$CompatibilityProfileRecord {
  const CompatibilityProfileRecord._();

  factory CompatibilityProfileRecord({
    required String id,
    required int profileVersion,
    required Iterable<ChildProcessCompatibilityRule> childProcessRules,
  }) {
    final validatedRules = childProcessRules.toIList();
    _validateChildProcessRuleSet(validatedRules);
    return CompatibilityProfileRecord._validated(
      id: ProfileId(id),
      profileVersion: ProfileVersion(profileVersion),
      childProcessRules: validatedRules,
    );
  }

  const factory CompatibilityProfileRecord._validated({
    required ProfileId id,
    required ProfileVersion profileVersion,
    required IList<ChildProcessCompatibilityRule> childProcessRules,
  }) = _CompatibilityProfileRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ChildProcessCompatibilityRule
    with _$ChildProcessCompatibilityRule {
  const ChildProcessCompatibilityRule._();

  factory ChildProcessCompatibilityRule({
    required String executableSuffix,
    required Iterable<String> appendArgumentsIfMissing,
  }) {
    final validatedSuffix = _validateChildProcessExecutableSuffix(
      executableSuffix,
    );
    final validatedArguments = appendArgumentsIfMissing
        .map(_validateChildProcessArgument)
        .toList(growable: false);
    if (validatedArguments.isEmpty) {
      throw ArgumentError.value(
        validatedArguments,
        'appendArgumentsIfMissing',
        'must contain at least one argument',
      );
    }
    if (validatedArguments.length > konyakMaxChildProcessRuleArguments) {
      throw ArgumentError.value(
        validatedArguments.length,
        'appendArgumentsIfMissing',
        'must contain at most $konyakMaxChildProcessRuleArguments arguments',
      );
    }
    if (validatedArguments.toSet().length != validatedArguments.length) {
      throw ArgumentError.value(
        validatedArguments,
        'appendArgumentsIfMissing',
        'must not contain duplicate arguments',
      );
    }
    return ChildProcessCompatibilityRule._validated(
      executableSuffix: ProgramExecutable(validatedSuffix),
      appendArgumentsIfMissing: ProgramRunArguments(validatedArguments),
    );
  }

  const factory ChildProcessCompatibilityRule._validated({
    required ProgramExecutable executableSuffix,
    required ProgramRunArguments appendArgumentsIfMissing,
  }) = _ChildProcessCompatibilityRule;
}

String _validateChildProcessExecutableSuffix(String value) {
  if (value.trim().isEmpty ||
      value.length > konyakMaxChildProcessExecutableSuffixLength ||
      !value.codeUnits.every(
        (codeUnit) => codeUnit >= 0x20 && codeUnit <= 0x7e,
      )) {
    throw ArgumentError.value(
      value,
      'executableSuffix',
      'must be non-blank, at most '
          '$konyakMaxChildProcessExecutableSuffixLength printable ASCII '
          'characters',
    );
  }
  return value;
}

String _validateChildProcessArgument(String value) {
  if (value.isEmpty ||
      value.length > konyakMaxChildProcessArgumentLength ||
      value.contains('\u0000') ||
      value.contains('\t') ||
      value.contains('\n') ||
      value.contains('\r') ||
      value.contains(' ') ||
      value.contains('"')) {
    throw ArgumentError.value(
      value,
      'appendArgumentsIfMissing',
      'each argument must be a non-empty unquoted token of at most '
          '$konyakMaxChildProcessArgumentLength characters',
    );
  }
  return value;
}

void _validateChildProcessRuleSet(IList<ChildProcessCompatibilityRule> rules) {
  final argumentCount = rules.fold<int>(
    0,
    (count, rule) => count + rule.appendArgumentsIfMissing.length,
  );
  if (argumentCount > konyakMaxChildProcessRuleArguments) {
    throw ArgumentError.value(
      argumentCount,
      'childProcessRules',
      'must contain at most $konyakMaxChildProcessRuleArguments '
          'child-process arguments',
    );
  }

  final entryLengths = rules
      .expand(
        (rule) => rule.appendArgumentsIfMissing.map(
          (argument) =>
              rule.executableSuffix.value.length + 1 + argument.length,
        ),
      )
      .toList(growable: false);
  final serializedLength =
      entryLengths.fold<int>(0, (length, entry) => length + entry) +
      (entryLengths.isEmpty ? 0 : entryLengths.length - 1);
  if (serializedLength > konyakMaxChildProcessRulesLength) {
    throw ArgumentError.value(
      serializedLength,
      'childProcessRules',
      'serialized rules must contain at most '
          '$konyakMaxChildProcessRulesLength UTF-16 code units',
    );
  }
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ProgramProfileRecord with _$ProgramProfileRecord {
  const ProgramProfileRecord._();

  factory ProgramProfileRecord({
    required String profileId,
    required int profileVersion,
    required String managedProgramPath,
    required String compatibilityProfileId,
    required int compatibilityProfileVersion,
  }) {
    return ProgramProfileRecord._validated(
      profileId: ProfileId(profileId),
      profileVersion: ProfileVersion(profileVersion),
      managedProgramPath: ProgramPath(managedProgramPath),
      compatibilityProfileId: ProfileId(compatibilityProfileId),
      compatibilityProfileVersion: ProfileVersion(compatibilityProfileVersion),
    );
  }

  const factory ProgramProfileRecord._validated({
    required ProfileId profileId,
    required ProfileVersion profileVersion,
    required ProgramPath managedProgramPath,
    required ProfileId compatibilityProfileId,
    required ProfileVersion compatibilityProfileVersion,
  }) = _ProgramProfileRecord;
}
