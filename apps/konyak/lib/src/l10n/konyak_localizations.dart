import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'konyak_localizations_en.dart';
import 'konyak_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of KonyakLocalizations
/// returned by `KonyakLocalizations.of(context)`.
///
/// Applications need to include `KonyakLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/konyak_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: KonyakLocalizations.localizationsDelegates,
///   supportedLocales: KonyakLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the KonyakLocalizations.supportedLocales
/// property.
abstract class KonyakLocalizations {
  KonyakLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static KonyakLocalizations of(BuildContext context) {
    return Localizations.of<KonyakLocalizations>(context, KonyakLocalizations)!;
  }

  static const LocalizationsDelegate<KonyakLocalizations> delegate =
      _KonyakLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// Konyak UI string: Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Konyak UI string: Advertise AVX Support
  ///
  /// In en, this message translates to:
  /// **'Advertise AVX Support'**
  String get advertiseAvxSupport;

  /// Konyak UI string: About Konyak
  ///
  /// In en, this message translates to:
  /// **'About Konyak'**
  String get aboutKonyak;

  /// Konyak UI string: Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Konyak UI string: Arguments
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get arguments;

  /// Konyak UI string: Additional Wine logging channels
  ///
  /// In en, this message translates to:
  /// **'Additional Wine logging channels'**
  String get additionalWineLoggingChannels;

  /// Konyak UI string: Auto
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// Konyak UI string: Automatically check for Konyak updates
  ///
  /// In en, this message translates to:
  /// **'Automatically check for Konyak updates'**
  String get automaticallyCheckForKonyakUpdates;

  /// Konyak UI string: Automatically check for Konyak Wine updates
  ///
  /// In en, this message translates to:
  /// **'Automatically check for Konyak Wine updates'**
  String get automaticallyCheckForKonyakWineUpdates;

  /// Konyak UI string: Automatically pin newly installed programs
  ///
  /// In en, this message translates to:
  /// **'Automatically pin newly installed programs'**
  String get automaticallyPinNewlyInstalledPrograms;

  /// Konyak UI string: Back to bottle
  ///
  /// In en, this message translates to:
  /// **'Back to bottle'**
  String get backToBottle;

  /// Konyak UI string: Bottle
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get bottle;

  /// Konyak UI string: Bottle Configuration
  ///
  /// In en, this message translates to:
  /// **'Bottle Configuration'**
  String get bottleConfiguration;

  /// Konyak UI string: Bottle path
  ///
  /// In en, this message translates to:
  /// **'Bottle path'**
  String get bottlePath;

  /// Konyak UI string: Bottles
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get bottles;

  /// Konyak UI string: Browse
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// Konyak UI string: Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Main menu item label for checking Konyak updates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates…'**
  String get checkForUpdatesMenuItem;

  /// Konyak UI string: Checking for Konyak updates...
  ///
  /// In en, this message translates to:
  /// **'Checking for Konyak updates...'**
  String get checkingForKonyakUpdatesEllipsis;

  /// Konyak UI string: Choose...
  ///
  /// In en, this message translates to:
  /// **'Choose...'**
  String get chooseEllipsis;

  /// Konyak UI string: Choose program file
  ///
  /// In en, this message translates to:
  /// **'Choose program file'**
  String get chooseProgramFile;

  /// Konyak UI string: Change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Konyak UI string: Clear Logging Channels
  ///
  /// In en, this message translates to:
  /// **'Clear Logging Channels'**
  String get clearLoggingChannels;

  /// Konyak UI string: Chinese (Simplified)
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get chineseSimplified;

  /// Konyak UI string: Chinese (Traditional)
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get chineseTraditional;

  /// Konyak UI string: Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Konyak UI string: Close window
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get closeWindow;

  /// Konyak UI string: Command Prompt
  ///
  /// In en, this message translates to:
  /// **'Command Prompt'**
  String get commandPrompt;

  /// Konyak UI string: Compatibility
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibility;

  /// Konyak UI string: Complete
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// Konyak UI string: Config
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get config;

  /// Konyak UI string: Control Panel
  ///
  /// In en, this message translates to:
  /// **'Control Panel'**
  String get controlPanel;

  /// Konyak UI string: Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Konyak UI string: Create Bottle
  ///
  /// In en, this message translates to:
  /// **'Create Bottle'**
  String get createBottle;

  /// Action label or tooltip for creating a bottle.
  ///
  /// In en, this message translates to:
  /// **'Create bottle'**
  String get createBottleAction;

  /// Konyak UI string: Creating bottle...
  ///
  /// In en, this message translates to:
  /// **'Creating bottle...'**
  String get creatingBottleEllipsis;

  /// Message shown in the open executable dialog when no bottles exist.
  ///
  /// In en, this message translates to:
  /// **'Create a bottle before running this executable.'**
  String get emptyExecutableBottleMessage;

  /// Message shown in the bottles list empty state.
  ///
  /// In en, this message translates to:
  /// **'Create a bottle to start managing Windows programs.'**
  String get emptyBottlesMessage;

  /// Konyak UI string: Could not load bottles
  ///
  /// In en, this message translates to:
  /// **'Could not load bottles'**
  String get couldNotLoadBottles;

  /// Konyak UI string: D3DMetal Backend
  ///
  /// In en, this message translates to:
  /// **'D3DMetal Backend'**
  String get d3dmetalBackend;

  /// Notice shown in runtime settings before importing Apple D3DMetal files.
  ///
  /// In en, this message translates to:
  /// **'D3DMetal is included in Apple Game Porting Toolkit. Konyak does not bundle or redistribute it. Download the GPTK DMG from Apple Developer, select the DMG, and review Apple License.pdf for commercial use or redistribution.'**
  String get d3dmetalLicenseNotice;

  /// Konyak UI string: Dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Konyak UI string: Default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Konyak UI string: Default bottle path:
  ///
  /// In en, this message translates to:
  /// **'Default bottle path:'**
  String get defaultBottlePath;

  /// Konyak UI string: Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Konyak UI string: Details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Konyak UI string: Options
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// Konyak UI string: DirectX Diagnostic Report
  ///
  /// In en, this message translates to:
  /// **'DirectX Diagnostic Report'**
  String get directxDiagnosticReport;

  /// Konyak UI string: Distribution
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// Konyak UI string: Download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Konyak UI string: DXVK HUD
  ///
  /// In en, this message translates to:
  /// **'DXVK HUD'**
  String get dxvkHud;

  /// Konyak UI string: Enhanced Sync
  ///
  /// In en, this message translates to:
  /// **'Enhanced Sync'**
  String get enhancedSync;

  /// Konyak UI string: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Konyak UI string: Environment
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// Konyak UI string: Export as Archive...
  ///
  /// In en, this message translates to:
  /// **'Export as Archive...'**
  String get exportAsArchiveEllipsis;

  /// Konyak UI string: Exporting bottle archive...
  ///
  /// In en, this message translates to:
  /// **'Exporting bottle archive...'**
  String get exportingBottleArchiveEllipsis;

  /// Konyak UI string: Failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Konyak UI string: File
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Konyak UI string: File Explorer
  ///
  /// In en, this message translates to:
  /// **'File Explorer'**
  String get fileExplorer;

  /// Konyak UI string: French
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// Konyak UI string: Full
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// Konyak UI string: General
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Konyak UI string: German
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// Konyak UI string: Graphics
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get graphics;

  /// Konyak UI string: Graphics Backend
  ///
  /// In en, this message translates to:
  /// **'Graphics Backend'**
  String get graphicsBackend;

  /// Button label for statically inspecting a program and suggesting a graphics backend.
  ///
  /// In en, this message translates to:
  /// **'Detect graphics backend'**
  String get detectGraphicsBackend;

  /// Konyak UI string: Create log file
  ///
  /// In en, this message translates to:
  /// **'Create log file'**
  String get createLogFile;

  /// Title for graphics backend static analysis results.
  ///
  /// In en, this message translates to:
  /// **'Graphics backend hint'**
  String get graphicsBackendHint;

  /// Message shown when static analysis finds no graphics backend suggestion.
  ///
  /// In en, this message translates to:
  /// **'No graphics backend hint was found.'**
  String get graphicsBackendHintUnavailable;

  /// Recommendation line for a graphics backend hint.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {backend}'**
  String recommendedGraphicsBackend(String backend);

  /// Line listing static analysis signals that informed the graphics backend hint.
  ///
  /// In en, this message translates to:
  /// **'Detected: {signals}'**
  String detectedGraphicsSignals(String signals);

  /// Konyak UI string: GPTK/D3DMetal source was not selected.
  ///
  /// In en, this message translates to:
  /// **'GPTK/D3DMetal source was not selected.'**
  String get gptkD3dmetalSourceWasNotSelected;

  /// Konyak UI string: GPTK version
  ///
  /// In en, this message translates to:
  /// **'GPTK version'**
  String get gptkImportVersion;

  /// Konyak UI string: Installed GPTK version
  ///
  /// In en, this message translates to:
  /// **'Installed GPTK version'**
  String get gptkInstalledVersion;

  /// Konyak UI string: GPTK 3
  ///
  /// In en, this message translates to:
  /// **'GPTK 3'**
  String get gptkImportVersionGptkThree;

  /// Konyak UI string: GPTK 4
  ///
  /// In en, this message translates to:
  /// **'GPTK 4'**
  String get gptkImportVersionGptkFour;

  /// Konyak UI string: High Resolution Mode
  ///
  /// In en, this message translates to:
  /// **'High Resolution Mode'**
  String get highResolutionMode;

  /// macOS native menu item label for hiding Konyak.
  ///
  /// In en, this message translates to:
  /// **'Hide Konyak'**
  String get hideKonyak;

  /// macOS native menu item label for hiding other applications.
  ///
  /// In en, this message translates to:
  /// **'Hide Others'**
  String get hideOthers;

  /// Konyak UI string: Incomplete
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// Konyak UI string: Import Bottle
  ///
  /// In en, this message translates to:
  /// **'Import Bottle'**
  String get importBottle;

  /// Konyak UI string: Import D3DMetal
  ///
  /// In en, this message translates to:
  /// **'Import D3DMetal'**
  String get importD3dmetal;

  /// Konyak UI string: Import D3DMetal Backend?
  ///
  /// In en, this message translates to:
  /// **'Import D3DMetal Backend?'**
  String get importD3dmetalBackend;

  /// Konyak UI string: Importing D3DMetal
  ///
  /// In en, this message translates to:
  /// **'Importing D3DMetal'**
  String get importingD3dmetal;

  /// Konyak UI string: Importing GPTK/D3DMetal...
  ///
  /// In en, this message translates to:
  /// **'Importing GPTK/D3DMetal...'**
  String get importingGptkD3dmetalEllipsis;

  /// Konyak UI string: Importing bottle archive...
  ///
  /// In en, this message translates to:
  /// **'Importing bottle archive...'**
  String get importingBottleArchiveEllipsis;

  /// Confirmation dialog message before importing Apple D3DMetal files.
  ///
  /// In en, this message translates to:
  /// **'Importing a GPTK app adds Apple D3DMetal files to the current macOS Wine runtime without replacing the Wine executable. Running Wine processes should be stopped before continuing.'**
  String get importD3dmetalBackendMessage;

  /// Konyak UI string: Install
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Konyak UI string: Installed
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// Konyak UI string: Installed Programs
  ///
  /// In en, this message translates to:
  /// **'Installed Programs'**
  String get installedPrograms;

  /// Konyak UI string: Installing
  ///
  /// In en, this message translates to:
  /// **'Installing'**
  String get installing;

  /// Konyak UI string: Italian
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// Konyak UI string: Japanese
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// Konyak UI string: Kill
  ///
  /// In en, this message translates to:
  /// **'Kill'**
  String get kill;

  /// Konyak UI string: Korean
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// Konyak UI string: Konyak Settings
  ///
  /// In en, this message translates to:
  /// **'Konyak Settings'**
  String get konyakSettings;

  /// Konyak UI string: Konyak is up to date.
  ///
  /// In en, this message translates to:
  /// **'Konyak is up to date.'**
  String get konyakIsUpToDate;

  /// Konyak UI string: Konyak update status is unknown.
  ///
  /// In en, this message translates to:
  /// **'Konyak update status is unknown.'**
  String get konyakUpdateStatusIsUnknown;

  /// Konyak UI string: Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Konyak UI string: Latest run log
  ///
  /// In en, this message translates to:
  /// **'Latest run log'**
  String get latestRunLog;

  /// Konyak UI string: Log file
  ///
  /// In en, this message translates to:
  /// **'Log file'**
  String get logFile;

  /// Konyak UI string: Logging
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get logging;

  /// Konyak UI string: Launching program...
  ///
  /// In en, this message translates to:
  /// **'Launching program...'**
  String get launchingProgramEllipsis;

  /// Konyak UI string: Light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Konyak UI string: Linux Runtime
  ///
  /// In en, this message translates to:
  /// **'Linux Runtime'**
  String get linuxRuntime;

  /// Konyak UI string: Loading
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Konyak UI string: Loading winetricks packages...
  ///
  /// In en, this message translates to:
  /// **'Loading winetricks packages...'**
  String get loadingWinetricksPackagesEllipsis;

  /// Konyak UI string: Locale
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get locale;

  /// Konyak UI string: macOS Runtime
  ///
  /// In en, this message translates to:
  /// **'macOS Runtime'**
  String get macosRuntime;

  /// Konyak UI string: Managed runtime installation is not supported.
  ///
  /// In en, this message translates to:
  /// **'Managed runtime installation is not supported.'**
  String get managedRuntimeInstallationIsNotSupported;

  /// Konyak UI string: Maximize or restore window
  ///
  /// In en, this message translates to:
  /// **'Maximize or restore window'**
  String get maximizeOrRestoreWindow;

  /// Konyak UI string: Metal HUD
  ///
  /// In en, this message translates to:
  /// **'Metal HUD'**
  String get metalHud;

  /// Konyak UI string: Metal Trace
  ///
  /// In en, this message translates to:
  /// **'Metal Trace'**
  String get metalTrace;

  /// Konyak UI string: Minimize window
  ///
  /// In en, this message translates to:
  /// **'Minimize window'**
  String get minimizeWindow;

  /// Konyak UI string: Missing
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// Konyak UI string: MIT License
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get mitLicense;

  /// Konyak UI string: Move
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Konyak UI string: Move...
  ///
  /// In en, this message translates to:
  /// **'Move...'**
  String get moveEllipsis;

  /// Konyak UI string: NAME
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get environmentNameHint;

  /// Konyak UI string: Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Konyak UI string: No Bottles
  ///
  /// In en, this message translates to:
  /// **'No Bottles'**
  String get noBottles;

  /// Konyak UI string: No bottles yet
  ///
  /// In en, this message translates to:
  /// **'No bottles yet'**
  String get noBottlesYet;

  /// Konyak UI string: No installed programs found.
  ///
  /// In en, this message translates to:
  /// **'No installed programs found.'**
  String get noInstalledProgramsFound;

  /// Konyak UI string: No managed runtime stack detected.
  ///
  /// In en, this message translates to:
  /// **'No managed runtime stack detected.'**
  String get noManagedRuntimeStackDetected;

  /// Konyak UI string: No matching winetricks verbs.
  ///
  /// In en, this message translates to:
  /// **'No matching winetricks verbs.'**
  String get noMatchingWinetricksVerbs;

  /// Konyak UI string: No verbs in this category.
  ///
  /// In en, this message translates to:
  /// **'No verbs in this category.'**
  String get noVerbsInThisCategory;

  /// Konyak UI string: No Wine processes found.
  ///
  /// In en, this message translates to:
  /// **'No Wine processes found.'**
  String get noWineProcessesFound;

  /// Konyak UI string: No winetricks verbs found.
  ///
  /// In en, this message translates to:
  /// **'No winetricks verbs found.'**
  String get noWinetricksVerbsFound;

  /// Konyak UI string: None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Konyak UI string: Not Now
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// Konyak UI string: Not installed
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get notInstalled;

  /// Konyak UI string: Off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// Konyak UI string: Open Bottle Folder
  ///
  /// In en, this message translates to:
  /// **'Open Bottle Folder'**
  String get openBottleFolder;

  /// Konyak UI string: Open C: Drive
  ///
  /// In en, this message translates to:
  /// **'Open C: Drive'**
  String get openCDrive;

  /// Konyak UI string: Open executable
  ///
  /// In en, this message translates to:
  /// **'Open executable'**
  String get openExecutable;

  /// Konyak UI string: Open GPTK Source
  ///
  /// In en, this message translates to:
  /// **'Open GPTK Source'**
  String get openGptkSource;

  /// Konyak UI string: Open Wine Configuration
  ///
  /// In en, this message translates to:
  /// **'Open Wine Configuration'**
  String get openWineConfiguration;

  /// Konyak UI string: Partial
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// Konyak UI string: Pin
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// Konyak UI string: Pin Program
  ///
  /// In en, this message translates to:
  /// **'Pin Program'**
  String get pinProgram;

  /// Konyak UI string: Process Manager
  ///
  /// In en, this message translates to:
  /// **'Process Manager'**
  String get processManager;

  /// Konyak UI string: Program
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// Konyak UI string: Program path
  ///
  /// In en, this message translates to:
  /// **'Program path'**
  String get programPath;

  /// Konyak UI string: Programs
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// macOS native menu item label for quitting Konyak.
  ///
  /// In en, this message translates to:
  /// **'Quit Konyak'**
  String get quitKonyak;

  /// Konyak UI string: Remove...
  ///
  /// In en, this message translates to:
  /// **'Remove...'**
  String get removeEllipsis;

  /// Konyak UI string: Repair
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repair;

  /// Konyak UI string: Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Konyak UI string: Refresh bottles
  ///
  /// In en, this message translates to:
  /// **'Refresh bottles'**
  String get refreshBottles;

  /// Konyak UI string: Registry Editor
  ///
  /// In en, this message translates to:
  /// **'Registry Editor'**
  String get registryEditor;

  /// Konyak UI string: Reinstall Linux Runtime
  ///
  /// In en, this message translates to:
  /// **'Reinstall Linux Runtime'**
  String get reinstallLinuxRuntime;

  /// macOS native menu item label for reinstalling the managed macOS runtime.
  ///
  /// In en, this message translates to:
  /// **'Reinstall macOS Runtime'**
  String get reinstallMacosRuntime;

  /// Konyak UI string: Remove environment variable
  ///
  /// In en, this message translates to:
  /// **'Remove environment variable'**
  String get removeEnvironmentVariable;

  /// Konyak UI string: Rename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Konyak UI string: Rename...
  ///
  /// In en, this message translates to:
  /// **'Rename...'**
  String get renameEllipsis;

  /// Konyak UI string: Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Konyak UI string: Runtime install
  ///
  /// In en, this message translates to:
  /// **'Runtime install'**
  String get runtimeInstall;

  /// Konyak UI string: Russian
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// Konyak UI string: Run
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// Konyak UI string: Run...
  ///
  /// In en, this message translates to:
  /// **'Run...'**
  String get runEllipsis;

  /// Konyak UI string: Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Konyak UI string: Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Konyak UI string: Search winetricks packages
  ///
  /// In en, this message translates to:
  /// **'Search winetricks packages'**
  String get searchWinetricksPackages;

  /// Konyak UI string: Select GPTK DMG
  ///
  /// In en, this message translates to:
  /// **'Select GPTK DMG'**
  String get selectGptkDmg;

  /// Konyak UI string: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Konyak UI string: Settings...
  ///
  /// In en, this message translates to:
  /// **'Settings...'**
  String get settingsEllipsis;

  /// Konyak UI string: Settings…
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get settingsEllipsisMenu;

  /// macOS native menu item label for showing all hidden applications.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// Konyak UI string: Show detail
  ///
  /// In en, this message translates to:
  /// **'Show detail'**
  String get showDetail;

  /// Konyak UI string: Show in File Manager
  ///
  /// In en, this message translates to:
  /// **'Show in File Manager'**
  String get showInFileManager;

  /// Konyak UI string: Show in Finder
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// Konyak UI string: Simulate Reboot
  ///
  /// In en, this message translates to:
  /// **'Simulate Reboot'**
  String get simulateReboot;

  /// Konyak UI string: Spanish
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Konyak UI string: Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Konyak UI string: Stop All Processes
  ///
  /// In en, this message translates to:
  /// **'Stop All Processes'**
  String get stopAllProcesses;

  /// Konyak UI string: System
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Konyak UI string: System Default
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Konyak UI string: Task Manager
  ///
  /// In en, this message translates to:
  /// **'Task Manager'**
  String get taskManager;

  /// Konyak UI string: Terminal
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// Konyak UI string: Terminate Wine processes when Konyak closes
  ///
  /// In en, this message translates to:
  /// **'Terminate Wine processes when Konyak closes'**
  String get terminateWineProcessesWhenKonyakCloses;

  /// Konyak UI string: Thai
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get thai;

  /// Konyak UI string: This removes the bottle folder and metadata.
  ///
  /// In en, this message translates to:
  /// **'This removes the bottle folder and metadata.'**
  String get thisRemovesTheBottleFolderAndMetadata;

  /// Konyak UI string: Tools
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Konyak UI string: Toggle sidebar
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get toggleSidebar;

  /// Konyak UI string: Ukrainian
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// Konyak UI string: Unavailable
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// Konyak UI string: Uninstall Programs
  ///
  /// In en, this message translates to:
  /// **'Uninstall Programs'**
  String get uninstallPrograms;

  /// Konyak UI string: Unpin
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// Konyak UI string: Updates
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// Konyak UI string: Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get environmentValueHint;

  /// Konyak UI string: View latest log
  ///
  /// In en, this message translates to:
  /// **'View latest log'**
  String get viewLatestLog;

  /// Konyak UI string: Relay (very verbose)
  ///
  /// In en, this message translates to:
  /// **'Relay (very verbose)'**
  String get wineLogRelay;

  /// Konyak UI string: File Access
  ///
  /// In en, this message translates to:
  /// **'File Access'**
  String get wineLogFileAccess;

  /// Konyak UI string: Fonts
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get wineLogFonts;

  /// Konyak UI string: Game Controllers
  ///
  /// In en, this message translates to:
  /// **'Game Controllers'**
  String get wineLogGameControllers;

  /// Konyak UI string: Game Graphics
  ///
  /// In en, this message translates to:
  /// **'Game Graphics'**
  String get wineLogGameGraphics;

  /// Konyak UI string: Keyboard Input
  ///
  /// In en, this message translates to:
  /// **'Keyboard Input'**
  String get wineLogKeyboardInput;

  /// Konyak UI string: Mouse Input
  ///
  /// In en, this message translates to:
  /// **'Mouse Input'**
  String get wineLogMouseInput;

  /// Konyak UI string: Network Connections
  ///
  /// In en, this message translates to:
  /// **'Network Connections'**
  String get wineLogNetworkConnections;

  /// Konyak UI string: Printing
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get wineLogPrinting;

  /// Konyak UI string: Sound (verbose)
  ///
  /// In en, this message translates to:
  /// **'Sound (verbose)'**
  String get wineLogSound;

  /// Konyak UI string: Window Behavior
  ///
  /// In en, this message translates to:
  /// **'Window Behavior'**
  String get wineLogWindowBehavior;

  /// Konyak UI string: View licenses
  ///
  /// In en, this message translates to:
  /// **'View licenses'**
  String get viewLicenses;

  /// Konyak UI string: Windows DPI
  ///
  /// In en, this message translates to:
  /// **'Windows DPI'**
  String get windowsDpi;

  /// Konyak UI string: Windows Version
  ///
  /// In en, this message translates to:
  /// **'Windows Version'**
  String get windowsVersion;

  /// Form field label for selecting the default Windows version.
  ///
  /// In en, this message translates to:
  /// **'Windows version'**
  String get windowsVersionFieldLabel;

  /// Wine runtime settings section title.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get wine;

  /// Winetricks bottom bar action label.
  ///
  /// In en, this message translates to:
  /// **'Winetricks'**
  String get winetricks;

  /// About dialog notice for runtime binary licensing.
  ///
  /// In en, this message translates to:
  /// **'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.'**
  String get runtimeLicensesNotice;

  /// Konyak UI string: {programName} Configuration
  ///
  /// In en, this message translates to:
  /// **'{programName} Configuration'**
  String programConfigurationTitle(String programName);

  /// Konyak UI string: Delete {bottleName}?
  ///
  /// In en, this message translates to:
  /// **'Delete {bottleName}?'**
  String deleteBottleTitle(String bottleName);

  /// Konyak UI string: Rename {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Rename {bottleName}'**
  String renameBottleTitle(String bottleName);

  /// Konyak UI string: Rename {programName}
  ///
  /// In en, this message translates to:
  /// **'Rename {programName}'**
  String renameProgramTitle(String programName);

  /// Konyak UI string: Move {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Move {bottleName}'**
  String moveBottleTitle(String bottleName);

  /// Konyak UI string: Installed programs in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Installed programs in {bottleName}'**
  String installedProgramsIn(String bottleName);

  /// Konyak UI string: Tools for {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Tools for {bottleName}'**
  String toolsForBottle(String bottleName);

  /// Konyak UI string: Pin program in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Pin program in {bottleName}'**
  String pinProgramIn(String bottleName);

  /// Konyak UI string: Run program in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Run program in {bottleName}'**
  String runProgramIn(String bottleName);

  /// Konyak UI string: Winetricks in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Winetricks in {bottleName}'**
  String winetricksIn(String bottleName);

  /// Konyak UI string: Pin program in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Pin program in {bottleName}'**
  String pinProgramTooltip(String bottleName);

  /// Konyak UI string: {path}
  /// Double-click to run
  ///
  /// In en, this message translates to:
  /// **'{path}\nDouble-click to run'**
  String pinnedProgramTooltip(String path);

  /// Konyak UI string: Download {runtimeName}?
  ///
  /// In en, this message translates to:
  /// **'Download {runtimeName}?'**
  String downloadRuntimeTitle(String runtimeName);

  /// Konyak UI string: Konyak will download {runtimeName} into your Konyak runtime directory. The runtime is separate from the application and remains under its own license.
  ///
  /// In en, this message translates to:
  /// **'Konyak will download {runtimeName} into your Konyak runtime directory. The runtime is separate from the application and remains under its own license.'**
  String downloadRuntimeMessage(String runtimeName);

  /// Konyak UI string: Install Konyak update?
  ///
  /// In en, this message translates to:
  /// **'Install Konyak update?'**
  String get installKonyakUpdateTitle;

  /// Konyak UI string: Install Konyak {latestVersion} update?
  ///
  /// In en, this message translates to:
  /// **'Install Konyak {latestVersion} update?'**
  String installKonyakVersionUpdateTitle(String latestVersion);

  /// Konyak UI string: A Konyak update is available. Install it now? Konyak will restart after the update starts.
  ///
  /// In en, this message translates to:
  /// **'A Konyak update is available. Install it now? Konyak will restart after the update starts.'**
  String get installKonyakUpdateMessage;

  /// Konyak UI string: Konyak {latestVersion} is available. Install it now? Konyak will restart after the update starts.
  ///
  /// In en, this message translates to:
  /// **'Konyak {latestVersion} is available. Install it now? Konyak will restart after the update starts.'**
  String installKonyakVersionUpdateMessage(String latestVersion);

  /// Konyak UI string: Installing {label} update. Konyak will restart.
  ///
  /// In en, this message translates to:
  /// **'Installing {label} update. Konyak will restart.'**
  String installingKonyakUpdate(String label);

  /// Konyak UI string: Install new {runtimeName} version?
  ///
  /// In en, this message translates to:
  /// **'Install new {runtimeName} version?'**
  String installRuntimeUpdateTitle(String runtimeName);

  /// Konyak UI string: Install {runtimeName} {latestVersion}?
  ///
  /// In en, this message translates to:
  /// **'Install {runtimeName} {latestVersion}?'**
  String installRuntimeVersionUpdateTitle(
    String runtimeName,
    String latestVersion,
  );

  /// Konyak UI string: A new {runtimeName} version is available. Install it now?
  ///
  /// In en, this message translates to:
  /// **'A new {runtimeName} version is available. Install it now?'**
  String installRuntimeUpdateMessage(String runtimeName);

  /// Konyak UI string: {runtimeName} {latestVersion} is available. Install it now?
  ///
  /// In en, this message translates to:
  /// **'{runtimeName} {latestVersion} is available. Install it now?'**
  String installRuntimeVersionUpdateMessage(
    String runtimeName,
    String latestVersion,
  );

  /// Konyak UI string: Installed {label}.
  ///
  /// In en, this message translates to:
  /// **'Installed {label}.'**
  String installedRuntimeUpdate(String label);

  /// Konyak UI string: {runtimeName} is on the latest version.
  ///
  /// In en, this message translates to:
  /// **'{runtimeName} is on the latest version.'**
  String runtimeIsUpToDate(String runtimeName);

  /// Konyak UI string: {runtimeName} version status is unknown.
  ///
  /// In en, this message translates to:
  /// **'{runtimeName} version status is unknown.'**
  String runtimeUpdateStatusIsUnknown(String runtimeName);

  /// Konyak UI string: Updates available: {labels}
  ///
  /// In en, this message translates to:
  /// **'Updates available: {labels}'**
  String updatesAvailable(String labels);

  /// Konyak UI string: Konyak update check failed: {message}
  ///
  /// In en, this message translates to:
  /// **'Konyak update check failed: {message}'**
  String konyakUpdateCheckFailed(String message);

  /// Konyak UI string: Konyak update install failed: {message}
  ///
  /// In en, this message translates to:
  /// **'Konyak update install failed: {message}'**
  String konyakUpdateInstallFailed(String message);

  /// Konyak UI string: {runtimeName} version check failed: {message}
  ///
  /// In en, this message translates to:
  /// **'{runtimeName} version check failed: {message}'**
  String runtimeUpdateCheckFailed(String runtimeName, String message);

  /// Konyak UI string: {runtimeName} version install failed: {message}
  ///
  /// In en, this message translates to:
  /// **'{runtimeName} version install failed: {message}'**
  String runtimeUpdateInstallFailed(String runtimeName, String message);

  /// Konyak UI string: Installed {runtimeName}
  ///
  /// In en, this message translates to:
  /// **'Installed {runtimeName}'**
  String installedRuntime(String runtimeName);

  /// Konyak UI string: Applied {profileName}
  ///
  /// In en, this message translates to:
  /// **'Applied {profileName}'**
  String appliedProfile(String profileName);

  /// Konyak UI string: Profile Manager
  ///
  /// In en, this message translates to:
  /// **'Profile Manager'**
  String get profileManager;

  /// Konyak UI string: Profile Manager in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Profile Manager in {bottleName}'**
  String profileManagerIn(String bottleName);

  /// Konyak UI string: Loading install profiles...
  ///
  /// In en, this message translates to:
  /// **'Loading install profiles...'**
  String get loadingInstallProfilesEllipsis;

  /// Konyak UI string: Loading profile details...
  ///
  /// In en, this message translates to:
  /// **'Loading profile details...'**
  String get loadingProfileDetailsEllipsis;

  /// Konyak UI string: Applying {profileName}...
  ///
  /// In en, this message translates to:
  /// **'Applying {profileName}...'**
  String applyingProfileEllipsis(String profileName);

  /// Konyak UI string: Apply profile
  ///
  /// In en, this message translates to:
  /// **'Apply profile'**
  String get applyProfile;

  /// Konyak UI string: Install automatically
  ///
  /// In en, this message translates to:
  /// **'Install automatically'**
  String get installProfileAutomatically;

  /// Konyak UI string: Import an install profile
  ///
  /// In en, this message translates to:
  /// **'Import...'**
  String get importProfileEllipsis;

  /// Konyak UI string: Edit a user install profile
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfile;

  /// Konyak UI string: Duplicate an install profile
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateProfile;

  /// Konyak UI string: Export an install profile
  ///
  /// In en, this message translates to:
  /// **'Export...'**
  String get exportProfileEllipsis;

  /// Konyak UI string: Edit the named profile manifest
  ///
  /// In en, this message translates to:
  /// **'Edit {profileName} JSON'**
  String editProfileManifest(String profileName);

  /// Konyak UI string: Duplicate the named profile manifest
  ///
  /// In en, this message translates to:
  /// **'Duplicate {profileName} JSON'**
  String duplicateProfileManifest(String profileName);

  /// Konyak UI string: Profile manifest JSON editor label
  ///
  /// In en, this message translates to:
  /// **'Profile manifest JSON'**
  String get profileManifestJson;

  /// Konyak UI string: Delete the named user profile
  ///
  /// In en, this message translates to:
  /// **'Delete {profileName}?'**
  String deleteProfile(String profileName);

  /// Konyak UI string: User profile deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete the user profile {profileName}? Applied bottle settings will not change.'**
  String deleteProfileMessage(String profileName);

  /// Konyak UI string: Importing a profile
  ///
  /// In en, this message translates to:
  /// **'Importing profile...'**
  String get importingProfileEllipsis;

  /// Konyak UI string: Updating a profile
  ///
  /// In en, this message translates to:
  /// **'Updating {profileName}...'**
  String updatingProfileEllipsis(String profileName);

  /// Konyak UI string: Exporting a profile
  ///
  /// In en, this message translates to:
  /// **'Exporting {profileName}...'**
  String exportingProfileEllipsis(String profileName);

  /// Konyak UI string: Deleting a profile
  ///
  /// In en, this message translates to:
  /// **'Deleting {profileName}...'**
  String deletingProfileEllipsis(String profileName);

  /// Konyak UI string: Imported a profile
  ///
  /// In en, this message translates to:
  /// **'Imported {profileName}'**
  String importedProfile(String profileName);

  /// Konyak UI string: Updated a profile
  ///
  /// In en, this message translates to:
  /// **'Updated {profileName}'**
  String updatedProfile(String profileName);

  /// Konyak UI string: Exported a profile
  ///
  /// In en, this message translates to:
  /// **'Exported {profileName}'**
  String exportedProfile(String profileName);

  /// Konyak UI string: Deleted a profile
  ///
  /// In en, this message translates to:
  /// **'Deleted {profileName}'**
  String deletedProfile(String profileName);

  /// Konyak UI string: Apply to existing program
  ///
  /// In en, this message translates to:
  /// **'Apply to existing program'**
  String get applyProfileToExistingProgram;

  /// Konyak UI string: No install profiles found.
  ///
  /// In en, this message translates to:
  /// **'No install profiles found.'**
  String get noInstallProfilesFound;

  /// Konyak UI string: Platforms
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get installProfilePlatforms;

  /// Konyak UI string: Profile source
  ///
  /// In en, this message translates to:
  /// **'Profile source'**
  String get installProfileSource;

  /// Konyak UI string: Installer URL
  ///
  /// In en, this message translates to:
  /// **'Installer URL'**
  String get installProfileInstallerUrl;

  /// Konyak UI string: Windows version
  ///
  /// In en, this message translates to:
  /// **'Windows version'**
  String get installProfileWindowsVersion;

  /// Konyak UI string: Default program path
  ///
  /// In en, this message translates to:
  /// **'Default program path'**
  String get installProfileManagedProgramPath;

  /// Konyak UI string: Dependencies
  ///
  /// In en, this message translates to:
  /// **'Dependencies'**
  String get installProfileDependencies;

  /// Konyak UI string: None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get installProfileNoDependencies;

  /// Konyak UI string: Run completion
  ///
  /// In en, this message translates to:
  /// **'Run completion'**
  String get installProfileRunCompletionPolicy;

  /// Konyak UI string: Compatibility rules
  ///
  /// In en, this message translates to:
  /// **'Compatibility rules'**
  String get installProfileCompatibilityRules;

  /// Konyak UI string: None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get installProfileNoCompatibilityRules;

  /// Konyak UI string: Reinstalled {runtimeName}
  ///
  /// In en, this message translates to:
  /// **'Reinstalled {runtimeName}'**
  String reinstalledRuntime(String runtimeName);

  /// Konyak UI string: Runtime install failed: {message}
  ///
  /// In en, this message translates to:
  /// **'Runtime install failed: {message}'**
  String runtimeInstallFailed(String message);

  /// Konyak UI string: Runtime reinstall failed: {message}
  ///
  /// In en, this message translates to:
  /// **'Runtime reinstall failed: {message}'**
  String runtimeReinstallFailed(String message);

  /// Konyak UI string: Deleted {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Deleted {bottleName}'**
  String deletedBottle(String bottleName);

  /// Konyak UI string: Renamed {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Renamed {bottleName}'**
  String renamedBottle(String bottleName);

  /// Konyak UI string: Moved {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Moved {bottleName}'**
  String movedBottle(String bottleName);

  /// Konyak UI string: Exported {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Exported {bottleName}'**
  String exportedBottle(String bottleName);

  /// Konyak UI string: Imported {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Imported {bottleName}'**
  String importedBottle(String bottleName);

  /// Konyak UI string: Pinned {programName}
  ///
  /// In en, this message translates to:
  /// **'Pinned {programName}'**
  String pinnedProgram(String programName);

  /// Konyak UI string: Unpinned {programName}
  ///
  /// In en, this message translates to:
  /// **'Unpinned {programName}'**
  String unpinnedProgram(String programName);

  /// Konyak UI string: Renamed {programName}
  ///
  /// In en, this message translates to:
  /// **'Renamed {programName}'**
  String renamedProgram(String programName);

  /// Konyak UI string: Opened {programName} location
  ///
  /// In en, this message translates to:
  /// **'Opened {programName} location'**
  String openedProgramLocation(String programName);

  /// Konyak UI string: Saved {programName} configuration
  ///
  /// In en, this message translates to:
  /// **'Saved {programName} configuration'**
  String savedProgramConfiguration(String programName);

  /// Konyak UI string: Opened {location}
  ///
  /// In en, this message translates to:
  /// **'Opened {location}'**
  String openedBottleLocation(String location);

  /// Konyak UI string: Terminated {processName}
  ///
  /// In en, this message translates to:
  /// **'Terminated {processName}'**
  String terminatedProcess(String processName);

  /// Konyak UI string: Stopped processes in {bottleName}
  ///
  /// In en, this message translates to:
  /// **'Stopped processes in {bottleName}'**
  String stoppedProcessesIn(String bottleName);

  /// Konyak UI string: Downloading {runtimeName}...
  ///
  /// In en, this message translates to:
  /// **'Downloading {runtimeName}...'**
  String downloadProgress(String runtimeName);

  /// Konyak UI string: Installing {verb}...
  ///
  /// In en, this message translates to:
  /// **'Installing {verb}...'**
  String installingVerb(String verb);

  /// Konyak UI string: {command} failed with exit code {exitCode}.
  ///
  /// In en, this message translates to:
  /// **'{command} failed with exit code {exitCode}.'**
  String commandFailedWithExitCode(String command, int exitCode);

  /// Konyak UI string: {command} failed with exit code {exitCode}: {diagnostic}
  ///
  /// In en, this message translates to:
  /// **'{command} failed with exit code {exitCode}: {diagnostic}'**
  String commandFailedWithDiagnostic(
    String command,
    int exitCode,
    String diagnostic,
  );

  /// Konyak UI string: C drive
  ///
  /// In en, this message translates to:
  /// **'C drive'**
  String get cDrive;

  /// Konyak UI string: bottle folder
  ///
  /// In en, this message translates to:
  /// **'bottle folder'**
  String get bottleFolder;

  /// Sidebar heading for invalid bottles that need explicit recovery.
  ///
  /// In en, this message translates to:
  /// **'Needs repair'**
  String get bottlesNeedRepair;

  /// Title for the invalid bottle recovery details dialog.
  ///
  /// In en, this message translates to:
  /// **'Bottle needs repair'**
  String get bottleNeedsRepair;

  /// Label for the storage directory identifier of an invalid bottle.
  ///
  /// In en, this message translates to:
  /// **'Storage ID'**
  String get storageIdentifier;

  /// Action that opens confirmation before removing incompatible profile settings.
  ///
  /// In en, this message translates to:
  /// **'Discard incompatible profile settings...'**
  String get discardIncompatibleProfileSettingsEllipsis;

  /// Confirmation title before removing incompatible profile settings.
  ///
  /// In en, this message translates to:
  /// **'Discard incompatible profile settings?'**
  String get discardIncompatibleProfileSettingsTitle;

  /// Confirmation explanation for bottle profile metadata recovery.
  ///
  /// In en, this message translates to:
  /// **'Konyak will back up the bottle metadata, then remove only the incompatible profile settings. The Wine prefix and installed programs will not be changed.'**
  String get discardIncompatibleProfileSettingsMessage;

  /// Confirmed action label for removing incompatible profile settings.
  ///
  /// In en, this message translates to:
  /// **'Discard profile settings'**
  String get discardProfileSettings;

  /// Progress label while repairing bottle metadata.
  ///
  /// In en, this message translates to:
  /// **'Repairing bottle metadata...'**
  String get repairingBottleMetadataEllipsis;

  /// Success message after repairing bottle metadata.
  ///
  /// In en, this message translates to:
  /// **'Profile settings discarded. Metadata backup: {backupPath}'**
  String repairedBottleMetadata(String backupPath);

  /// Label for the directory used as the current working directory when a program starts.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get workingDirectory;

  /// Program working directory option that uses the executable parent folder.
  ///
  /// In en, this message translates to:
  /// **'Executable folder (default)'**
  String get executableDirectory;

  /// Program working directory option that uses a custom bottle-local folder.
  ///
  /// In en, this message translates to:
  /// **'Custom folder'**
  String get customWorkingDirectory;

  /// Label for a custom Windows C drive working directory path.
  ///
  /// In en, this message translates to:
  /// **'Custom folder path'**
  String get customWorkingDirectoryPath;
}

class _KonyakLocalizationsDelegate
    extends LocalizationsDelegate<KonyakLocalizations> {
  const _KonyakLocalizationsDelegate();

  @override
  Future<KonyakLocalizations> load(Locale locale) {
    return SynchronousFuture<KonyakLocalizations>(
      lookupKonyakLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_KonyakLocalizationsDelegate old) => false;
}

KonyakLocalizations lookupKonyakLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return KonyakLocalizationsEn();
    case 'ja':
      return KonyakLocalizationsJa();
  }

  throw FlutterError(
    'KonyakLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
