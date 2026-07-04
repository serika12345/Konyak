import 'support/cli_contract_full_helpers.dart';

void main() {
  group('runtime install request type fronts', () {
    test('macOS full install accepts typed source manifest options', () {
      const sourceManifestUrl = 'https://example.invalid/macos/source.json';
      const sourceManifestSignatureUrl =
          'https://example.invalid/macos/source.json.sig';
      final request = MacosWineInstallRequest.fullInstall(
        sourceManifest: Option.of(RuntimeSourceManifestUrl(sourceManifestUrl)),
        sourceManifestSignature: Option.of(
          RuntimeSourceManifestSignatureUrl(sourceManifestSignatureUrl),
        ),
        force: true,
        emitProgress: true,
      );

      expect(request.sourceManifest.toNullable(), sourceManifestUrl);
      expect(
        request.sourceManifestSignature.toNullable(),
        sourceManifestSignatureUrl,
      );
      expect(
        request.requestOperation.sourceManifest.toNullable(),
        RuntimeSourceManifestUrl(sourceManifestUrl),
      );
      expect(
        request.requestOperation.sourceManifestSignature.toNullable(),
        RuntimeSourceManifestSignatureUrl(sourceManifestSignatureUrl),
      );
      expect(request.force, isTrue);
      expect(request.emitProgress, isTrue);
    });

    test('macOS component install accepts typed archive paths', () {
      final componentArchivePaths = <RuntimeArchivePath>[
        RuntimeArchivePath('/tmp/dxvk.tar.xz'),
      ];
      final request = MacosWineInstallRequest.componentInstall(
        archivePath: Option.of(RuntimeArchivePath('/tmp/runtime.tar.xz')),
        archiveSha256: Option.of(RuntimeArchiveChecksumValue('runtime-sha256')),
        componentArchivePaths: componentArchivePaths,
      );
      componentArchivePaths.add(RuntimeArchivePath('/tmp/vkd3d.tar.xz'));

      expect(request.archivePath.toNullable(), '/tmp/runtime.tar.xz');
      expect(request.archiveSha256.toNullable(), 'runtime-sha256');
      expect(request.componentArchivePaths, ['/tmp/dxvk.tar.xz']);
      expect(
        request.requestOperation.archivePath.toNullable(),
        RuntimeArchivePath('/tmp/runtime.tar.xz'),
      );
      expect(request.requestOperation.componentArchivePaths, [
        RuntimeArchivePath('/tmp/dxvk.tar.xz'),
      ]);
    });

    test('Linux update install accepts typed remote archive options', () {
      final request = LinuxWineInstallRequest.updateInstall(
        archiveUrl: Option.of(
          RuntimeArchiveUrl('https://example.invalid/linux/runtime.tar.xz'),
        ),
        archiveSha256: Option.of(RuntimeArchiveChecksumValue('linux-sha256')),
        force: true,
      );

      expect(
        request.archiveUrl.toNullable(),
        'https://example.invalid/linux/runtime.tar.xz',
      );
      expect(request.archiveSha256.toNullable(), 'linux-sha256');
      expect(
        request.requestOperation.archiveUrl.toNullable(),
        RuntimeArchiveUrl('https://example.invalid/linux/runtime.tar.xz'),
      );
      expect(
        request.requestOperation.archiveSha256.toNullable(),
        RuntimeArchiveChecksumValue('linux-sha256'),
      );
      expect(request.operation, RuntimeInstallOperation.updateInstall);
      expect(request.force, isTrue);
    });
  });
}
