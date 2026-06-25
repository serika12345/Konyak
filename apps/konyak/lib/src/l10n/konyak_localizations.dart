import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../settings/app_settings_summary.dart';

class KonyakLocalizations {
  const KonyakLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('ja')];

  static const LocalizationsDelegate<KonyakLocalizations> delegate =
      _KonyakLocalizationsDelegate();

  static KonyakLocalizations of(BuildContext context) {
    final localizations = Localizations.of<KonyakLocalizations>(
      context,
      KonyakLocalizations,
    );
    assert(localizations != null, 'KonyakLocalizations is not configured.');
    return localizations!;
  }

  bool get _isJapanese => locale.languageCode == 'ja';

  String text(String source) {
    if (!_isJapanese) {
      return source;
    }

    return _jaText[source] ?? source;
  }

  Map<String, String> textMap(Map<String, String> source) {
    return <String, String>{
      for (final entry in source.entries) entry.key: text(entry.value),
    };
  }

  String languageModeLabel(AppLanguageMode mode) {
    return switch (mode) {
      AppLanguageMode.system => text('System Default'),
      AppLanguageMode.english => text('English'),
      AppLanguageMode.japanese => text('Japanese'),
    };
  }

  Locale? localeForLanguageMode(AppLanguageMode mode) {
    return switch (mode) {
      AppLanguageMode.system => null,
      AppLanguageMode.english => const Locale('en'),
      AppLanguageMode.japanese => const Locale('ja'),
    };
  }

  String programConfigurationTitle(String programName) {
    return _isJapanese ? '$programName の設定' : '$programName Configuration';
  }

  String deleteBottleTitle(String bottleName) {
    return _isJapanese ? '$bottleName を削除しますか？' : 'Delete $bottleName?';
  }

  String renameBottleTitle(String bottleName) {
    return _isJapanese ? '$bottleName の名前を変更' : 'Rename $bottleName';
  }

  String renameProgramTitle(String programName) {
    return _isJapanese ? '$programName の名前を変更' : 'Rename $programName';
  }

  String moveBottleTitle(String bottleName) {
    return _isJapanese ? '$bottleName を移動' : 'Move $bottleName';
  }

  String installedProgramsIn(String bottleName) {
    return _isJapanese
        ? '$bottleName のインストール済みプログラム'
        : 'Installed programs in $bottleName';
  }

  String toolsForBottle(String bottleName) {
    return _isJapanese ? '$bottleName のツール' : 'Tools for $bottleName';
  }

  String pinProgramIn(String bottleName) {
    return _isJapanese
        ? '$bottleName にプログラムをピン留め'
        : 'Pin program in $bottleName';
  }

  String runProgramIn(String bottleName) {
    return _isJapanese ? '$bottleName でプログラムを実行' : 'Run program in $bottleName';
  }

  String winetricksIn(String bottleName) {
    return _isJapanese
        ? '$bottleName の Winetricks'
        : 'Winetricks in $bottleName';
  }

  String pinProgramTooltip(String bottleName) {
    return _isJapanese
        ? '$bottleName にプログラムをピン留め'
        : 'Pin program in $bottleName';
  }

  String pinnedProgramTooltip(String path) {
    return _isJapanese ? '$path\nダブルクリックで実行' : '$path\nDouble-click to run';
  }

  String downloadRuntimeTitle(String runtimeName) {
    return _isJapanese ? '$runtimeName をダウンロードしますか？' : 'Download $runtimeName?';
  }

  String downloadRuntimeMessage(String runtimeName) {
    return _isJapanese
        ? 'Konyak は $runtimeName を Konyak のランタイムディレクトリにダウンロードします。ランタイムはアプリケーションとは別に管理され、独自のライセンスに従います。'
        : 'Konyak will download $runtimeName into your Konyak runtime directory. '
              'The runtime is separate from the application and remains under its own license.';
  }

  String installKonyakUpdateTitle(String? latestVersion) {
    if (_isJapanese) {
      return latestVersion == null
          ? 'Konyak アップデートをインストールしますか？'
          : 'Konyak $latestVersion アップデートをインストールしますか？';
    }

    return latestVersion == null
        ? 'Install Konyak update?'
        : 'Install Konyak $latestVersion update?';
  }

  String installKonyakUpdateMessage(String? latestVersion) {
    if (_isJapanese) {
      return latestVersion == null
          ? 'Konyak のアップデートがあります。今すぐインストールしますか？アップデート開始後に Konyak は再起動します。'
          : 'Konyak $latestVersion があります。今すぐインストールしますか？アップデート開始後に Konyak は再起動します。';
    }

    return latestVersion == null
        ? 'A Konyak update is available. Install it now? Konyak will restart after the update starts.'
        : 'Konyak $latestVersion is available. Install it now? Konyak will restart after the update starts.';
  }

  String installingKonyakUpdate(String label) {
    return _isJapanese
        ? '$label アップデートをインストールしています。Konyak は再起動します。'
        : 'Installing $label update. Konyak will restart.';
  }

  String updatesAvailable(Iterable<String> labels) {
    final joined = labels.join(', ');
    return _isJapanese ? '利用可能なアップデート: $joined' : 'Updates available: $joined';
  }

  String konyakUpdateCheckFailed(String message) {
    return _isJapanese
        ? 'Konyak アップデート確認に失敗しました: $message'
        : 'Konyak update check failed: $message';
  }

  String konyakUpdateInstallFailed(String message) {
    return _isJapanese
        ? 'Konyak アップデートのインストールに失敗しました: $message'
        : 'Konyak update install failed: $message';
  }

  String installedRuntime(String runtimeName) {
    return _isJapanese ? '$runtimeName をインストールしました' : 'Installed $runtimeName';
  }

  String reinstalledRuntime(String runtimeName) {
    return _isJapanese
        ? '$runtimeName を再インストールしました'
        : 'Reinstalled $runtimeName';
  }

  String runtimeInstallFailed(String message) {
    return _isJapanese
        ? 'ランタイムのインストールに失敗しました: $message'
        : 'Runtime install failed: $message';
  }

  String runtimeReinstallFailed(String message) {
    return _isJapanese
        ? 'ランタイムの再インストールに失敗しました: $message'
        : 'Runtime reinstall failed: $message';
  }

  String deletedBottle(String bottleName) {
    return _isJapanese ? '$bottleName を削除しました' : 'Deleted $bottleName';
  }

  String renamedBottle(String bottleName) {
    return _isJapanese ? '$bottleName に名前を変更しました' : 'Renamed $bottleName';
  }

  String movedBottle(String bottleName) {
    return _isJapanese ? '$bottleName を移動しました' : 'Moved $bottleName';
  }

  String exportedBottle(String bottleName) {
    return _isJapanese ? '$bottleName をエクスポートしました' : 'Exported $bottleName';
  }

  String importedBottle(String bottleName) {
    return _isJapanese ? '$bottleName をインポートしました' : 'Imported $bottleName';
  }

  String pinnedProgram(String programName) {
    return _isJapanese ? '$programName をピン留めしました' : 'Pinned $programName';
  }

  String unpinnedProgram(String programName) {
    return _isJapanese ? '$programName のピン留めを解除しました' : 'Unpinned $programName';
  }

  String renamedProgram(String programName) {
    return _isJapanese ? '$programName に名前を変更しました' : 'Renamed $programName';
  }

  String openedProgramLocation(String programName) {
    return _isJapanese
        ? '$programName の場所を開きました'
        : 'Opened $programName location';
  }

  String savedProgramConfiguration(String programName) {
    return _isJapanese
        ? '$programName の設定を保存しました'
        : 'Saved $programName configuration';
  }

  String openedBottleLocation(String location) {
    return _isJapanese ? '$location を開きました' : 'Opened $location';
  }

  String terminatedProcess(String processName) {
    return _isJapanese ? '$processName を終了しました' : 'Terminated $processName';
  }

  String stoppedProcessesIn(String bottleName) {
    return _isJapanese
        ? '$bottleName のプロセスを停止しました'
        : 'Stopped processes in $bottleName';
  }

  String downloadProgress(String runtimeName) {
    return _isJapanese
        ? '$runtimeName をダウンロードしています...'
        : 'Downloading $runtimeName...';
  }

  String installingVerb(String verb) {
    return _isJapanese ? '$verb をインストールしています...' : 'Installing $verb...';
  }

  String locationLabel(String location) {
    return switch (location) {
      'c-drive' => _isJapanese ? 'C ドライブ' : 'C drive',
      'root' => _isJapanese ? 'ボトルフォルダ' : 'bottle folder',
      _ => location,
    };
  }

  String commandFailedWithExitCode(String command, int exitCode) {
    return _isJapanese
        ? '$command が終了コード $exitCode で失敗しました。'
        : '$command failed with exit code $exitCode.';
  }

  String commandFailedWithDiagnostic(
    String command,
    int exitCode,
    String diagnostic,
  ) {
    return _isJapanese
        ? '$command が終了コード $exitCode で失敗しました: $diagnostic'
        : '$command failed with exit code $exitCode: $diagnostic';
  }
}

class _KonyakLocalizationsDelegate
    extends LocalizationsDelegate<KonyakLocalizations> {
  const _KonyakLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' || locale.languageCode == 'ja';
  }

  @override
  Future<KonyakLocalizations> load(Locale locale) {
    final languageCode = locale.languageCode == 'ja' ? 'ja' : 'en';
    return SynchronousFuture<KonyakLocalizations>(
      KonyakLocalizations(Locale(languageCode)),
    );
  }

  @override
  bool shouldReload(_KonyakLocalizationsDelegate old) {
    return false;
  }
}

const _jaText = <String, String>{
  'Add': '追加',
  'Advertise AVX Support': 'AVX サポートを通知',
  'About Konyak': 'Konyak について',
  'Appearance': '外観',
  'Arguments': '引数',
  'Auto': '自動',
  'Automatically check for Konyak updates': 'Konyak のアップデートを自動確認',
  'Automatically check for Konyak Wine updates': 'Konyak Wine のアップデートを自動確認',
  'Automatically pin newly installed programs': '新しくインストールされたプログラムを自動でピン留め',
  'Back to bottle': 'ボトルに戻る',
  'Bottle': 'ボトル',
  'Bottle Configuration': 'ボトル設定',
  'Bottle path': 'ボトルパス',
  'Bottles': 'ボトル',
  'Browse': '参照',
  'Cancel': 'キャンセル',
  'Check for Updates...': 'アップデートを確認...',
  'Check for Updates…': 'アップデートを確認...',
  'Checking for Konyak updates...': 'Konyak のアップデートを確認しています...',
  'Choose...': '選択...',
  'Choose program file': 'プログラムファイルを選択',
  'Chinese (Simplified)': '中国語（簡体字）',
  'Chinese (Traditional)': '中国語（繁体字）',
  'Close': '閉じる',
  'Close window': 'ウィンドウを閉じる',
  'Command Prompt': 'コマンドプロンプト',
  'Compatibility': '互換性',
  'Complete': '完了',
  'Config': '設定',
  'Control Panel': 'コントロールパネル',
  'Create': '作成',
  'Create Bottle': 'ボトルを作成',
  'Create bottle': 'ボトルを作成',
  'Creating bottle...': 'ボトルを作成しています...',
  'Create a bottle before running this executable.':
      'この実行ファイルを起動する前にボトルを作成してください。',
  'Create a bottle to start managing Windows programs.':
      'Windows プログラムを管理するにはボトルを作成してください。',
  'Could not load bottles': 'ボトルを読み込めませんでした',
  'D3DMetal Backend': 'D3DMetal バックエンド',
  'D3DMetal is included in Apple Game Porting Toolkit. Konyak does not bundle or redistribute it. Download the GPTK DMG from Apple Developer, select the DMG, and review Apple License.pdf for commercial use or redistribution.':
      'D3DMetal は Apple Game Porting Toolkit に含まれます。Konyak は D3DMetal を同梱または再配布しません。Apple Developer から GPTK DMG をダウンロードして DMG を選択し、商用利用または再配布について Apple License.pdf を確認してください。',
  'Dark': 'ダーク',
  'Default': 'デフォルト',
  'Default bottle path:': 'デフォルトのボトルパス:',
  'Delete': '削除',
  'Details': '詳細',
  'DirectX Diagnostic Report': 'DirectX 診断レポート',
  'Distribution': '配布',
  'Download': 'ダウンロード',
  'DXVK HUD': 'DXVK HUD',
  'Enhanced Sync': 'Enhanced Sync',
  'English': '英語',
  'Environment': '環境変数',
  'Export as Archive...': 'アーカイブとしてエクスポート...',
  'Exporting bottle archive...': 'ボトルアーカイブを書き出しています...',
  'Failed': '失敗',
  'File': 'ファイル',
  'File Explorer': 'ファイルエクスプローラー',
  'French': 'フランス語',
  'Full': 'フル',
  'General': '一般',
  'German': 'ドイツ語',
  'Graphics': 'グラフィック',
  'Graphics Backend': 'グラフィックバックエンド',
  'GPTK/D3DMetal source was not selected.': 'GPTK/D3DMetal の入手元が選択されていません。',
  'High Resolution Mode': '高解像度モード',
  'Incomplete': '未完了',
  'Import Bottle': 'ボトルをインポート',
  'Import D3DMetal': 'D3DMetal をインポート',
  'Import D3DMetal Backend?': 'D3DMetal バックエンドをインポートしますか？',
  'Importing D3DMetal': 'D3DMetal をインポートしています',
  'Importing GPTK/D3DMetal...': 'GPTK/D3DMetal をインポートしています...',
  'Importing bottle archive...': 'ボトルアーカイブを読み込んでいます...',
  'Importing a GPTK app adds Apple D3DMetal files to the current macOS Wine runtime without replacing the Wine executable. Running Wine processes should be stopped before continuing.':
      'GPTK アプリをインポートすると、Wine 実行ファイルを置き換えずに Apple D3DMetal ファイルを現在の macOS Wine ランタイムへ追加します。続行する前に実行中の Wine プロセスを停止してください。',
  'Install': 'インストール',
  'Installed': 'インストール済み',
  'Installed Programs': 'インストール済みプログラム',
  'Installing': 'インストール中',
  'Italian': 'イタリア語',
  'Japanese': '日本語',
  'Kill': '終了',
  'Korean': '韓国語',
  'Konyak Settings': 'Konyak 設定',
  'Konyak is up to date.': 'Konyak は最新です。',
  'Konyak update status is unknown.': 'Konyak のアップデート状態は不明です。',
  'Language': '言語',
  'Latest run log': '最新の実行ログ',
  'Launching program...': 'プログラムを起動しています...',
  'Light': 'ライト',
  'Linux Runtime': 'Linux ランタイム',
  'Loading': '読み込み中',
  'Loading winetricks packages...': 'winetricks パッケージを読み込んでいます...',
  'Locale': 'ロケール',
  'macOS Runtime': 'macOS ランタイム',
  'Managed runtime installation is not supported.':
      '管理対象ランタイムのインストールはサポートされていません。',
  'Maximize or restore window': '最大化または復元',
  'Metal HUD': 'Metal HUD',
  'Metal Trace': 'Metal Trace',
  'Minimize window': 'ウィンドウを最小化',
  'Missing': '不足',
  'MIT License': 'MIT ライセンス',
  'Move': '移動',
  'Move...': '移動...',
  'NAME': '名前',
  'Name': '名前',
  'No Bottles': 'ボトルがありません',
  'No bottles yet': 'ボトルはまだありません',
  'No installed programs found.': 'インストール済みプログラムは見つかりませんでした。',
  'No managed runtime stack detected.': '管理対象ランタイムスタックは検出されませんでした。',
  'No matching winetricks verbs.': '一致する winetricks verb はありません。',
  'No verbs in this category.': 'このカテゴリに verb はありません。',
  'No Wine processes found.': 'Wine プロセスは見つかりませんでした。',
  'No winetricks verbs found.': 'winetricks verb は見つかりませんでした。',
  'None': 'なし',
  'Not Now': 'あとで',
  'Not installed': '未インストール',
  'Off': 'オフ',
  'Open Bottle Folder': 'ボトルフォルダを開く',
  'Open C: Drive': 'C: ドライブを開く',
  'Open executable': '実行ファイルを開く',
  'Open GPTK Source': 'GPTK 入手元を開く',
  'Open Wine Configuration': 'Wine 設定を開く',
  'Partial': '一部',
  'Pin': 'ピン留め',
  'Pin Program': 'プログラムをピン留め',
  'Process Manager': 'プロセスマネージャー',
  'Program': 'プログラム',
  'Program path': 'プログラムパス',
  'Programs': 'プログラム',
  'Remove...': '削除...',
  'Repair': '修復',
  'Refresh': '更新',
  'Refresh bottles': 'ボトルを更新',
  'Registry Editor': 'レジストリエディター',
  'Reinstall Linux Runtime': 'Linux ランタイムを再インストール',
  'Remove environment variable': '環境変数を削除',
  'Rename': '名前を変更',
  'Rename...': '名前を変更...',
  'Retry': '再試行',
  'Runtime install': 'ランタイムインストール',
  'Russian': 'ロシア語',
  'Run': '実行',
  'Run...': '実行...',
  'Run…': '実行...',
  'Save': '保存',
  'Search': '検索',
  'Search winetricks packages': 'winetricks パッケージを検索',
  'Select GPTK DMG': 'GPTK DMG を選択',
  'Settings': '設定',
  'Settings...': '設定...',
  'Settings…': '設定...',
  'Show detail': '詳細を表示',
  'Show in File Manager': 'ファイルマネージャーで表示',
  'Show in Finder': 'Finder に表示',
  'Simulate Reboot': '再起動をシミュレート',
  'Spanish': 'スペイン語',
  'Status': '状態',
  'Stop All Processes': 'すべてのプロセスを停止',
  'System': 'システム',
  'System Default': 'システム設定',
  'Task Manager': 'タスクマネージャー',
  'Terminal': 'ターミナル',
  'Terminate Wine processes when Konyak closes': 'Konyak を閉じるときに Wine プロセスを終了',
  'Thai': 'タイ語',
  'This removes the bottle folder and metadata.': 'ボトルフォルダとメタデータを削除します。',
  'Tools': 'ツール',
  'Toggle sidebar': 'サイドバーを切り替え',
  'Ukrainian': 'ウクライナ語',
  'Unavailable': '利用不可',
  'Uninstall Programs': 'プログラムをアンインストール',
  'Unpin': 'ピン留め解除',
  'Updates': 'アップデート',
  'Value': '値',
  'View latest log': '最新ログを表示',
  'View licenses': 'ライセンスを表示',
  'Windows DPI': 'Windows DPI',
  'Windows Version': 'Windows バージョン',
  'Windows version': 'Windows バージョン',
  'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.':
      'Wine/Proton ランタイムバイナリは起動後にダウンロードされ、それぞれのライセンスに従います。',
};
