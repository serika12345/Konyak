import 'dart:io';

import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';
import '../utils/program_labels.dart';

class BottleProgramsDialog extends StatelessWidget {
  const BottleProgramsDialog({
    super.key,
    required this.bottleName,
    required this.programs,
    required this.onPinProgram,
    required this.onRunProgram,
  });

  final String bottleName;
  final List<BottleProgramSummary> programs;
  final ValueChanged<BottleProgramSummary> onPinProgram;
  final ValueChanged<BottleProgramSummary> onRunProgram;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Installed programs in $bottleName'),
      content: SizedBox(
        width: 560,
        child: programs.isEmpty
            ? const Text('No installed programs found.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final program = programs[index];
                  return ListTile(
                    leading: _ProgramIcon(program: program),
                    title: Text(programDisplayName(program)),
                    subtitle: Text(programSubtitle(program)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => onPinProgram(program),
                          icon: const Icon(Icons.push_pin_outlined, size: 16),
                          label: const Text('Pin'),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => onRunProgram(program),
                          child: const Text('Run'),
                        ),
                      ],
                    ),
                    onTap: () => onRunProgram(program),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ProgramIcon extends StatelessWidget {
  const _ProgramIcon({required this.program});

  final BottleProgramSummary program;

  @override
  Widget build(BuildContext context) {
    final iconPath = program.metadata?.iconPath;
    if (iconPath == null || iconPath.trim().isEmpty) {
      return const Icon(Icons.shortcut);
    }

    return Image.file(
      File(iconPath),
      width: 28,
      height: 28,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shortcut),
    );
  }
}
