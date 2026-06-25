import 'dart:async';

import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../cli/konyak_cli_client.dart';
import '../utils/program_labels.dart';
import '../widgets/icon_file_image.dart';
import '../widgets/konyak_snack_bar.dart';

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
  List<WineProcessSummary> _processes = const <WineProcessSummary>[];
  final Set<String> _terminatingProcessKeys = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProcesses());
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.onLoadProcesses();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      switch (result) {
        case LoadedWineProcesses(:final processes):
          _processes = processes;
        case WineProcessListLoadFailure(:final message):
          _errorMessage = message;
      }
    });
  }

  Future<void> _terminateProcess(WineProcessSummary process) async {
    final key = _processKey(process);
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
        _processes = _processes
            .where((candidate) => _processKey(candidate) != key)
            .toList(growable: false);
      }
    });

    final message = switch (result) {
      TerminatedWineProcesses() => 'Terminated ${_processDisplayName(process)}',
      WineProcessTerminationLoadFailure(:final message) => message,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(konyakSnackBar(context: context, message: message));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('process-manager-dialog'),
      title: const Text('Process Manager'),
      content: SizedBox(width: 620, child: _content()),
      actions: [
        TextButton.icon(
          key: const ValueKey('process-manager-refresh'),
          onPressed: _isLoading ? null : _loadProcesses,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _content() {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return SizedBox(height: 180, child: Center(child: Text(errorMessage)));
    }

    if (_processes.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No Wine processes found.')),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _processes.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final process = _processes[index];
          final key = _processKey(process);
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
              label: const Text('Kill'),
            ),
          );
        },
      ),
    );
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
      key: ValueKey('process-manager-process-icon-${_processKey(process)}'),
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

String _processKey(WineProcessSummary process) {
  return '${process.bottleId}-${process.processId}';
}
