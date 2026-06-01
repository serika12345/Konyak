part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderWineProcesses on _KonyakHomeLoaderState {
  void _terminateWineProcessesOnClose() {
    if (!widget.enableBackgroundServices || _hasTerminatedWineProcesses) {
      return;
    }

    final settings = _appSettings;
    if (settings == null || !settings.terminateWineProcessesOnClose) {
      return;
    }

    _hasTerminatedWineProcesses = true;
    unawaited(widget.cliClient.terminateWineProcesses());
  }

  Future<void> _terminateBottleProcesses(BottleSummary bottle) async {
    final result = await widget.cliClient.terminateWineProcesses(
      bottleId: bottle.id,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      TerminatedWineProcesses() => 'Stopped processes in ${bottle.name}',
      WineProcessTerminationLoadFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

  Future<void> _showProcessManager() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ProcessManagerDialog(
        bottles: _bottles,
        onLoadProcesses: widget.cliClient.listWineProcesses,
        onTerminateProcess: (process) {
          return widget.cliClient.terminateWineProcess(
            bottleId: process.bottleId,
            processId: process.processId,
          );
        },
      ),
    );
  }

  Future<void> _showLatestLog() async {
    final logPath = _latestRunLogPath;
    if (logPath == null) {
      return;
    }

    final result = await widget.logReader.readLog(logPath);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ReadLog(:final content):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Latest run log'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(child: SelectableText(content)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case LogReadFailure(:final message):
        _showSnackBar(message);
    }
  }
}
