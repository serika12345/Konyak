import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';

class WineLoggingChannelMenu extends StatelessWidget {
  const WineLoggingChannelMenu({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: localizations.additionalWineLoggingChannels,
      icon: const Icon(Icons.add),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '',
          child: Text(localizations.clearLoggingChannels),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '+relay',
          child: Text(localizations.wineLogRelay),
        ),
        PopupMenuItem<String>(
          value: '+file',
          child: Text(localizations.wineLogFileAccess),
        ),
        PopupMenuItem<String>(
          value: '+font',
          child: Text(localizations.wineLogFonts),
        ),
        PopupMenuItem<String>(
          value: '+dinput,+xinput',
          child: Text(localizations.wineLogGameControllers),
        ),
        PopupMenuItem<String>(
          value: '+d3d,+vulkan,+dxgi',
          child: Text(localizations.wineLogGameGraphics),
        ),
        PopupMenuItem<String>(
          value: '+keyboard',
          child: Text(localizations.wineLogKeyboardInput),
        ),
        PopupMenuItem<String>(
          value: '+mouse',
          child: Text(localizations.wineLogMouseInput),
        ),
        PopupMenuItem<String>(
          value: '+winsock',
          child: Text(localizations.wineLogNetworkConnections),
        ),
        PopupMenuItem<String>(
          value: '+print',
          child: Text(localizations.wineLogPrinting),
        ),
        PopupMenuItem<String>(
          value: '+wave,+alsa,+coreaudio',
          child: Text(localizations.wineLogSound),
        ),
        PopupMenuItem<String>(
          value: '+win,+event',
          child: Text(localizations.wineLogWindowBehavior),
        ),
      ],
    );
  }
}

void appendWineLoggingChannels(
  TextEditingController controller,
  String channels,
) {
  if (channels.isEmpty) {
    controller.clear();
    return;
  }

  final current = controller.text.trim();
  controller.text = current.isEmpty ? channels : '$current,$channels';
}
