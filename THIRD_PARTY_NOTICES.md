# Third-Party Notices

Konyak application artifacts are distributed under the MIT License.

Wine/Proton runtime binaries are not bundled in Konyak application artifacts.
Konyak downloads and installs managed runtime components after launch into the
user's Konyak runtime directory. Those runtime components remain separate works
under their own licenses, and runtime component archives must carry the
applicable license notices and source availability information for the exact
components they contain.

Runtime components currently supported by Konyak include:

- Wine: LGPL-2.1-or-later, https://www.winehq.org/
- Winetricks: LGPL-2.1, https://github.com/Winetricks/winetricks
- DXVK: zlib, https://github.com/doitsujin/dxvk
- DXVK-macOS: follows its upstream project notices for the shipped archive.
- vkd3d-proton: LGPL-2.1, https://github.com/HansKristian-Work/vkd3d-proton
- MoltenVK: Apache-2.0, https://github.com/KhronosGroup/MoltenVK
- GStreamer: LGPL, https://gstreamer.freedesktop.org/
- wine-mono: see the downloaded wine-mono package notices for the shipped
  release.
- GPTK/D3DMetal: optional and not redistributed by Konyak unless a future
  distribution path is reviewed separately.
