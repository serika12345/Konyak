import 'package:flutter/material.dart';

const konyakWindowBackground = Color(0xff282828);
const konyakSidebarBackground = Color(0xff444443);
const konyakSidebarSearchBackground = Color(0xff565655);
const konyakBorder = Color(0xff585858);
const konyakStrongBorder = Color(0xff171717);
const konyakText = Color(0xffe6e6e6);
const konyakMutedText = Color(0xff9b9b9b);
const konyakAccent = Color(0xffff861a);
const konyakButtonBackground = Color(0xff575757);
const konyakDarkColors = KonyakThemeColors(
  brightness: Brightness.dark,
  windowBackground: konyakWindowBackground,
  sidebarBackground: konyakSidebarBackground,
  sidebarSearchBackground: konyakSidebarSearchBackground,
  sidebarSearchBorder: Color(0xff696969),
  border: konyakBorder,
  strongBorder: konyakStrongBorder,
  divider: Color(0xff3b3b3b),
  text: konyakText,
  mutedText: konyakMutedText,
  accent: konyakAccent,
  accentText: Colors.white,
  buttonBackground: konyakButtonBackground,
  buttonDisabledForeground: Color(0xff777777),
  buttonDisabledBackground: Color(0xff3d3d3d),
  toolbarIcon: konyakMutedText,
  toolbarDisabledIcon: Color(0xff5c5c5c),
  sidebarIcon: Color(0xffb8b8b8),
  dialogBackground: Color(0xff2b3033),
  overlayPanelBackground: Color(0xff303030),
  inputBackground: Color(0xff242424),
  menuBackground: Color(0xff242728),
  menuBorder: Color(0xff4d4d4d),
  actionTrailingIcon: Color(0xff555555),
  programTileSelectedBackground: Color(0xff383838),
  programTileSelectedBorder: Color(0xff626262),
  pinnedProgramIcon: Color(0xffa0a0a0),
  pinProgramBorder: Color(0xff707070),
  pinProgramIcon: Color(0xff777777),
  toggleEnabledOnTrack: konyakAccent,
  toggleEnabledOffTrack: Color(0xff565656),
  toggleDisabledOnTrack: Color(0xff4a433d),
  toggleDisabledOffTrack: Color(0xff3f3f3f),
  toggleEnabledOnBorder: Color(0xffffa347),
  toggleEnabledOffBorder: Color(0xff7a7a7a),
  toggleDisabledOnBorder: Color(0xff66584d),
  toggleDisabledOffBorder: Color(0xff4a4a4a),
  toggleEnabledThumb: Color(0xffdedede),
  toggleDisabledThumb: Color(0xff242424),
);
const konyakLightColors = KonyakThemeColors(
  brightness: Brightness.light,
  windowBackground: Color(0xfff7f7f5),
  sidebarBackground: Color(0xffe9e9e4),
  sidebarSearchBackground: Color(0xfffbfbfa),
  sidebarSearchBorder: Color(0xffc7c7c1),
  border: Color(0xffcfcfca),
  strongBorder: Color(0xffbdbdb7),
  divider: Color(0xffdcdcd6),
  text: Color(0xff24211f),
  mutedText: Color(0xff67645f),
  accent: konyakAccent,
  accentText: Colors.white,
  buttonBackground: Color(0xffdeded8),
  buttonDisabledForeground: Color(0xffa1a19b),
  buttonDisabledBackground: Color(0xffecece8),
  toolbarIcon: Color(0xff6a6762),
  toolbarDisabledIcon: Color(0xffbab9b3),
  sidebarIcon: Color(0xff5e5b56),
  dialogBackground: Color(0xffffffff),
  overlayPanelBackground: Color(0xffffffff),
  inputBackground: Color(0xffffffff),
  menuBackground: Color(0xffffffff),
  menuBorder: Color(0xffd0d0ca),
  actionTrailingIcon: Color(0xff77746e),
  programTileSelectedBackground: Color(0xffffead6),
  programTileSelectedBorder: Color(0xffffc58a),
  pinnedProgramIcon: Color(0xff77746e),
  pinProgramBorder: Color(0xffa9a7a0),
  pinProgramIcon: Color(0xff77746e),
  toggleEnabledOnTrack: konyakAccent,
  toggleEnabledOffTrack: Color(0xffcecec8),
  toggleDisabledOnTrack: Color(0xffffdfbf),
  toggleDisabledOffTrack: Color(0xffdeded8),
  toggleEnabledOnBorder: Color(0xffff9d3d),
  toggleEnabledOffBorder: Color(0xffaaa9a2),
  toggleDisabledOnBorder: Color(0xffffc58a),
  toggleDisabledOffBorder: Color(0xffc7c7c1),
  toggleEnabledThumb: Color(0xffffffff),
  toggleDisabledThumb: Color(0xfff5f5f2),
);
const sidebarExpandedWidth = 190.0;
const sidebarCollapsedWidth = 44.0;
const sidebarAnimationDuration = Duration(milliseconds: 180);
const sidebarAnimationCurve = Curves.easeInOutCubic;
const bottleDetailPadding = EdgeInsets.fromLTRB(20, 14, 20, 10);
const minimumBottleDetailContentHeight = 0.0;
const macosWineRuntimeId = 'konyak-macos-wine';
const linuxWineRuntimeId = 'konyak-linux-wine';

ThemeData konyakThemeData(KonyakThemeColors colors) {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: colors.brightness,
      ).copyWith(
        primary: colors.accent,
        secondary: colors.accent,
        surface: colors.windowBackground,
        onSurface: colors.text,
      );

  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'Inter',
    fontFamilyFallback: const [
      'Noto Sans JP',
      'Hiragino Sans',
      'Hiragino Sans GB',
      'AppleGothic',
      'Yu Gothic',
      'Noto Sans CJK JP',
      'Noto Sans JP',
      'sans-serif',
    ],
    scaffoldBackgroundColor: colors.windowBackground,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.overlayPanelBackground,
      contentTextStyle: TextStyle(color: colors.text),
    ),
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[colors],
  );
}

@immutable
class KonyakThemeColors extends ThemeExtension<KonyakThemeColors> {
  const KonyakThemeColors({
    required this.brightness,
    required this.windowBackground,
    required this.sidebarBackground,
    required this.sidebarSearchBackground,
    required this.sidebarSearchBorder,
    required this.border,
    required this.strongBorder,
    required this.divider,
    required this.text,
    required this.mutedText,
    required this.accent,
    required this.accentText,
    required this.buttonBackground,
    required this.buttonDisabledForeground,
    required this.buttonDisabledBackground,
    required this.toolbarIcon,
    required this.toolbarDisabledIcon,
    required this.sidebarIcon,
    required this.dialogBackground,
    required this.overlayPanelBackground,
    required this.inputBackground,
    required this.menuBackground,
    required this.menuBorder,
    required this.actionTrailingIcon,
    required this.programTileSelectedBackground,
    required this.programTileSelectedBorder,
    required this.pinnedProgramIcon,
    required this.pinProgramBorder,
    required this.pinProgramIcon,
    required this.toggleEnabledOnTrack,
    required this.toggleEnabledOffTrack,
    required this.toggleDisabledOnTrack,
    required this.toggleDisabledOffTrack,
    required this.toggleEnabledOnBorder,
    required this.toggleEnabledOffBorder,
    required this.toggleDisabledOnBorder,
    required this.toggleDisabledOffBorder,
    required this.toggleEnabledThumb,
    required this.toggleDisabledThumb,
  });

  final Brightness brightness;
  final Color windowBackground;
  final Color sidebarBackground;
  final Color sidebarSearchBackground;
  final Color sidebarSearchBorder;
  final Color border;
  final Color strongBorder;
  final Color divider;
  final Color text;
  final Color mutedText;
  final Color accent;
  final Color accentText;
  final Color buttonBackground;
  final Color buttonDisabledForeground;
  final Color buttonDisabledBackground;
  final Color toolbarIcon;
  final Color toolbarDisabledIcon;
  final Color sidebarIcon;
  final Color dialogBackground;
  final Color overlayPanelBackground;
  final Color inputBackground;
  final Color menuBackground;
  final Color menuBorder;
  final Color actionTrailingIcon;
  final Color programTileSelectedBackground;
  final Color programTileSelectedBorder;
  final Color pinnedProgramIcon;
  final Color pinProgramBorder;
  final Color pinProgramIcon;
  final Color toggleEnabledOnTrack;
  final Color toggleEnabledOffTrack;
  final Color toggleDisabledOnTrack;
  final Color toggleDisabledOffTrack;
  final Color toggleEnabledOnBorder;
  final Color toggleEnabledOffBorder;
  final Color toggleDisabledOnBorder;
  final Color toggleDisabledOffBorder;
  final Color toggleEnabledThumb;
  final Color toggleDisabledThumb;

  static KonyakThemeColors of(BuildContext context) {
    return Theme.of(context).extension<KonyakThemeColors>() ?? konyakDarkColors;
  }

  @override
  KonyakThemeColors copyWith({
    Brightness? brightness,
    Color? windowBackground,
    Color? sidebarBackground,
    Color? sidebarSearchBackground,
    Color? sidebarSearchBorder,
    Color? border,
    Color? strongBorder,
    Color? divider,
    Color? text,
    Color? mutedText,
    Color? accent,
    Color? accentText,
    Color? buttonBackground,
    Color? buttonDisabledForeground,
    Color? buttonDisabledBackground,
    Color? toolbarIcon,
    Color? toolbarDisabledIcon,
    Color? sidebarIcon,
    Color? dialogBackground,
    Color? overlayPanelBackground,
    Color? inputBackground,
    Color? menuBackground,
    Color? menuBorder,
    Color? actionTrailingIcon,
    Color? programTileSelectedBackground,
    Color? programTileSelectedBorder,
    Color? pinnedProgramIcon,
    Color? pinProgramBorder,
    Color? pinProgramIcon,
    Color? toggleEnabledOnTrack,
    Color? toggleEnabledOffTrack,
    Color? toggleDisabledOnTrack,
    Color? toggleDisabledOffTrack,
    Color? toggleEnabledOnBorder,
    Color? toggleEnabledOffBorder,
    Color? toggleDisabledOnBorder,
    Color? toggleDisabledOffBorder,
    Color? toggleEnabledThumb,
    Color? toggleDisabledThumb,
  }) {
    return KonyakThemeColors(
      brightness: brightness ?? this.brightness,
      windowBackground: windowBackground ?? this.windowBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarSearchBackground:
          sidebarSearchBackground ?? this.sidebarSearchBackground,
      sidebarSearchBorder: sidebarSearchBorder ?? this.sidebarSearchBorder,
      border: border ?? this.border,
      strongBorder: strongBorder ?? this.strongBorder,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonDisabledForeground:
          buttonDisabledForeground ?? this.buttonDisabledForeground,
      buttonDisabledBackground:
          buttonDisabledBackground ?? this.buttonDisabledBackground,
      toolbarIcon: toolbarIcon ?? this.toolbarIcon,
      toolbarDisabledIcon: toolbarDisabledIcon ?? this.toolbarDisabledIcon,
      sidebarIcon: sidebarIcon ?? this.sidebarIcon,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      overlayPanelBackground:
          overlayPanelBackground ?? this.overlayPanelBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      menuBackground: menuBackground ?? this.menuBackground,
      menuBorder: menuBorder ?? this.menuBorder,
      actionTrailingIcon: actionTrailingIcon ?? this.actionTrailingIcon,
      programTileSelectedBackground:
          programTileSelectedBackground ?? this.programTileSelectedBackground,
      programTileSelectedBorder:
          programTileSelectedBorder ?? this.programTileSelectedBorder,
      pinnedProgramIcon: pinnedProgramIcon ?? this.pinnedProgramIcon,
      pinProgramBorder: pinProgramBorder ?? this.pinProgramBorder,
      pinProgramIcon: pinProgramIcon ?? this.pinProgramIcon,
      toggleEnabledOnTrack: toggleEnabledOnTrack ?? this.toggleEnabledOnTrack,
      toggleEnabledOffTrack:
          toggleEnabledOffTrack ?? this.toggleEnabledOffTrack,
      toggleDisabledOnTrack:
          toggleDisabledOnTrack ?? this.toggleDisabledOnTrack,
      toggleDisabledOffTrack:
          toggleDisabledOffTrack ?? this.toggleDisabledOffTrack,
      toggleEnabledOnBorder:
          toggleEnabledOnBorder ?? this.toggleEnabledOnBorder,
      toggleEnabledOffBorder:
          toggleEnabledOffBorder ?? this.toggleEnabledOffBorder,
      toggleDisabledOnBorder:
          toggleDisabledOnBorder ?? this.toggleDisabledOnBorder,
      toggleDisabledOffBorder:
          toggleDisabledOffBorder ?? this.toggleDisabledOffBorder,
      toggleEnabledThumb: toggleEnabledThumb ?? this.toggleEnabledThumb,
      toggleDisabledThumb: toggleDisabledThumb ?? this.toggleDisabledThumb,
    );
  }

  @override
  KonyakThemeColors lerp(ThemeExtension<KonyakThemeColors>? other, double t) {
    if (other is! KonyakThemeColors) {
      return this;
    }

    return KonyakThemeColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      windowBackground: Color.lerp(
        windowBackground,
        other.windowBackground,
        t,
      )!,
      sidebarBackground: Color.lerp(
        sidebarBackground,
        other.sidebarBackground,
        t,
      )!,
      sidebarSearchBackground: Color.lerp(
        sidebarSearchBackground,
        other.sidebarSearchBackground,
        t,
      )!,
      sidebarSearchBorder: Color.lerp(
        sidebarSearchBorder,
        other.sidebarSearchBorder,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      strongBorder: Color.lerp(strongBorder, other.strongBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      buttonBackground: Color.lerp(
        buttonBackground,
        other.buttonBackground,
        t,
      )!,
      buttonDisabledForeground: Color.lerp(
        buttonDisabledForeground,
        other.buttonDisabledForeground,
        t,
      )!,
      buttonDisabledBackground: Color.lerp(
        buttonDisabledBackground,
        other.buttonDisabledBackground,
        t,
      )!,
      toolbarIcon: Color.lerp(toolbarIcon, other.toolbarIcon, t)!,
      toolbarDisabledIcon: Color.lerp(
        toolbarDisabledIcon,
        other.toolbarDisabledIcon,
        t,
      )!,
      sidebarIcon: Color.lerp(sidebarIcon, other.sidebarIcon, t)!,
      dialogBackground: Color.lerp(
        dialogBackground,
        other.dialogBackground,
        t,
      )!,
      overlayPanelBackground: Color.lerp(
        overlayPanelBackground,
        other.overlayPanelBackground,
        t,
      )!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      menuBackground: Color.lerp(menuBackground, other.menuBackground, t)!,
      menuBorder: Color.lerp(menuBorder, other.menuBorder, t)!,
      actionTrailingIcon: Color.lerp(
        actionTrailingIcon,
        other.actionTrailingIcon,
        t,
      )!,
      programTileSelectedBackground: Color.lerp(
        programTileSelectedBackground,
        other.programTileSelectedBackground,
        t,
      )!,
      programTileSelectedBorder: Color.lerp(
        programTileSelectedBorder,
        other.programTileSelectedBorder,
        t,
      )!,
      pinnedProgramIcon: Color.lerp(
        pinnedProgramIcon,
        other.pinnedProgramIcon,
        t,
      )!,
      pinProgramBorder: Color.lerp(
        pinProgramBorder,
        other.pinProgramBorder,
        t,
      )!,
      pinProgramIcon: Color.lerp(pinProgramIcon, other.pinProgramIcon, t)!,
      toggleEnabledOnTrack: Color.lerp(
        toggleEnabledOnTrack,
        other.toggleEnabledOnTrack,
        t,
      )!,
      toggleEnabledOffTrack: Color.lerp(
        toggleEnabledOffTrack,
        other.toggleEnabledOffTrack,
        t,
      )!,
      toggleDisabledOnTrack: Color.lerp(
        toggleDisabledOnTrack,
        other.toggleDisabledOnTrack,
        t,
      )!,
      toggleDisabledOffTrack: Color.lerp(
        toggleDisabledOffTrack,
        other.toggleDisabledOffTrack,
        t,
      )!,
      toggleEnabledOnBorder: Color.lerp(
        toggleEnabledOnBorder,
        other.toggleEnabledOnBorder,
        t,
      )!,
      toggleEnabledOffBorder: Color.lerp(
        toggleEnabledOffBorder,
        other.toggleEnabledOffBorder,
        t,
      )!,
      toggleDisabledOnBorder: Color.lerp(
        toggleDisabledOnBorder,
        other.toggleDisabledOnBorder,
        t,
      )!,
      toggleDisabledOffBorder: Color.lerp(
        toggleDisabledOffBorder,
        other.toggleDisabledOffBorder,
        t,
      )!,
      toggleEnabledThumb: Color.lerp(
        toggleEnabledThumb,
        other.toggleEnabledThumb,
        t,
      )!,
      toggleDisabledThumb: Color.lerp(
        toggleDisabledThumb,
        other.toggleDisabledThumb,
        t,
      )!,
    );
  }
}
