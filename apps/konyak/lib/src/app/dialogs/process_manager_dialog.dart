import 'dart:async';

import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../cli/konyak_cli_client.dart';
import '../../l10n/konyak_localizations.dart';
import '../utils/program_labels.dart';
import '../widgets/icon_file_image.dart';
import '../widgets/konyak_snack_bar.dart';
import 'process_manager_state.dart';

class ProcessManagerDialog extends StatefulWidget {
  const ProcessManagerDialog({
    super.key,
    required this.bottles,
    required this.onLoadProcesses,
    required this.onTerminateProcess,
  });

  final List<BottleSummary> bottles;
  final Future<WineProcessListLoadResult> Function() onLoadProcesses;
  final Future<WineProcessTerminationLoadResult> Function(
    WineProcessSummary process,
  )
  onTerminateProcess;

  @override
  State<ProcessManagerDialog> createState() => _ProcessManagerDialogState();
}

class _ProcessManagerDialogState extends State<ProcessManagerDialog> {
  ProcessManagerState _processState = const ProcessManagerState.loading();
  final Set<String> _terminatingProcessKeys = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadProcesses());
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _processState = const ProcessManagerState.loading();
    });

    final result = await widget.onLoadProcesses();

    if (!mounted) {
      return;
    }

    setState(() {
      _processState = processManagerStateFromLoadResult(result);
    });
  }

  Future<void> _terminateProcess(WineProcessSummary process) async {
    final key = processManagerProcessKey(process);
    setState(() {
      _terminatingProcessKeys.add(key);
    });

    final result = await widget.onTerminateProcess(process);

    if (!mounted) {
      return;
    }

    setState(() {
      _terminatingProcessKeys.remove(key);
      if (result is TerminatedWineProcesses) {
        _processState = removeProcessFromManagerState(
          state: _processState,
          processKey: key,
        );
      }
    });

    final message = switch (result) {
      TerminatedWineProcesses() => KonyakLocalizations.of(
        context,
      ).terminatedProcess(_processDisplayName(process)),
      WineProcessTerminationLoadFailure(:final message) => message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(konyakSnackBar(context: context, message: message));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      key: const ValueKey('process-manager-dialog'),
      title: Text(localizations.processManager),
      content: SizedBox(width: 620, child: _content()),
      actions: [
        TextButton.icon(
          key: const ValueKey('process-manager-refresh'),
          onPressed: isProcessManagerLoading(_processState)
              ? null
              : _loadProcesses,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(localizations.refresh),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.close),
        ),
      ],
    );
  }

  Widget _content() {
    return switch (_processState) {
      LoadingProcessManagerState() => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      FailedProcessManagerState(:final message) => SizedBox(
        height: 180,
        child: Center(child: Text(message)),
      ),
      LoadedProcessManagerState(:final processes) when processes.isEmpty =>
        SizedBox(
          height: 180,
          child: Center(
            child: Text(KonyakLocalizations.of(context).noWineProcessesFound),
          ),
        ),
      LoadedProcessManagerState(:final processes) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: processes.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final process = processes[index];
            final key = processManagerProcessKey(process);
            final isTerminating = _terminatingProcessKeys.contains(key);
            return ListTile(
              key: ValueKey('process-manager-process-$key'),
              contentPadding: EdgeInsets.zero,
              leading: _ProcessIcon(process: process),
              title: Text(
                _processDisplayName(process),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _processSubtitle(process),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton.icon(
                key: ValueKey('process-manager-kill-$key'),
                onPressed: isTerminating
                    ? null
                    : () => unawaited(_terminateProcess(process)),
                icon: isTerminating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close, size: 16),
                label: Text(KonyakLocalizations.of(context).kill),
              ),
            );
          },
        ),
      ),
    };
  }

  String _processSubtitle(WineProcessSummary process) {
    final bottleName = _bottleName(process.bottleId);
    final path = process.hostPath ?? process.executable;
    return '$bottleName - ${process.processId} - $path';
  }

  String _bottleName(String bottleId) {
    for (final bottle in widget.bottles) {
      if (bottle.id == bottleId) {
        return bottle.name;
      }
    }

    return bottleId;
  }
}

class _ProcessIcon extends StatelessWidget {
  const _ProcessIcon({required this.process});

  final WineProcessSummary process;

  @override
  Widget build(BuildContext context) {
    return IconFileImage(
      key: ValueKey(
        'process-manager-process-icon-${processManagerProcessKey(process)}',
      ),
      path: process.metadata?.iconPath,
      width: 28,
      height: 28,
      fallback: const Icon(Icons.memory_outlined),
    );
  }
}

String _processDisplayName(WineProcessSummary process) {
  final metadataName = process.metadata?.displayName.trim() ?? '';
  if (metadataName.isNotEmpty) {
    return metadataName;
  }

  return defaultProgramName(process.executable.replaceAll('\\', '/'));
}
