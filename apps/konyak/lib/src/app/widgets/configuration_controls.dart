import 'package:flutter/material.dart';

import '../app_constants.dart';
import 'konyak_toggle.dart';

class ConfigurationTextField extends StatelessWidget {
  const ConfigurationTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return SizedBox(
      width: 260,
      height: 30,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: colors.text, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colors.mutedText, fontSize: 13),
          isDense: true,
          filled: true,
          fillColor: colors.inputBackground,
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIcon == null
              ? null
              : const BoxConstraints.tightFor(width: 30, height: 30),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.mutedText),
          ),
        ),
      ),
    );
  }
}

class BottleConfigurationSection extends StatelessWidget {
  const BottleConfigurationSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_down, size: 18, color: colors.text),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  Divider(height: 1, color: colors.divider, indent: 14),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class BottleConfigurationRow extends StatelessWidget {
  const BottleConfigurationRow({
    super.key,
    required this.label,
    required this.trailing,
  });

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.mutedText, fontSize: 14),
            ),
          ),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class BottleConfigurationSwitchRow extends StatelessWidget {
  const BottleConfigurationSwitchRow({
    super.key,
    this.switchKey,
    this.loadingKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  final Key? switchKey;
  final Key? loadingKey;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return BottleConfigurationRow(
      label: label,
      trailing: isLoading
          ? SizedBox(
              key: loadingKey,
              width: 36,
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  KonyakToggle(key: switchKey, value: value, onChanged: null),
                  const SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            )
          : KonyakToggle(key: switchKey, value: value, onChanged: onChanged),
    );
  }
}

class ConfigurationDropdown extends StatelessWidget {
  const ConfigurationDropdown({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
    this.width = 210,
  });

  final String value;
  final Map<String, String> labels;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final menuLabels = <String, String>{
      ...labels,
      if (!labels.containsKey(value)) value: value,
    };

    return SizedBox(
      width: width,
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        style: TextStyle(
          color: KonyakThemeColors.of(context).text,
          fontSize: 13,
        ),
        items: menuLabels.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value == null) {
                  return;
                }
                onChanged!(value);
              },
      ),
    );
  }
}
