import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';
import '../../l10n/konyak_localizations.dart';
import '../utils/program_labels.dart';
import '../widgets/icon_file_image.dart';

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
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.installedProgramsIn(bottleName)),
      content: SizedBox(
        width: 560,
        child: programs.isEmpty
            ? Text(localizations.noInstalledProgramsFound)
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
                          label: Text(localizations.pin),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => onRunProgram(program),
                          child: Text(localizations.run),
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
          child: Text(localizations.close),
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
    return IconFileImage(
      path: program.metadata?.iconPath,
      width: 28,
      height: 28,
      fallback: const Icon(Icons.shortcut),
    );
  }
}
