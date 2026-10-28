# bop-vlckit

Small Bricktory's changes to VideoLAN's MobileVLCKit 3.7.4 for the iOS app bop: a build with the GPL-licensed code removed.

## Contents

- `vlckit-3.7.4-bop1.patch`: one commit on VLCKit tag `3.7.4`; iOS minimum 27.0.
- `tools/gpl_scan.py`: license-header scanner.
- `LICENSE`: GNU Lesser General Public License 2.1.

## Changes

1. libzvbi disabled (`--disable-zvbi` in the contrib bootstrap and VLC configure).
2. Module blacklist: `librotate_plugin`, `libvod_rtsp_plugin`, `libstream_out_rtp_plugin`, `libsyslog_plugin`, `libmono_plugin`, `libdolby_surround_decoder_plugin`, `libdummy_plugin`.
3. VLC patch 0047: removes `yadif.h`, `yadif_template.h` and `algo_yadif.c/.h` from the deinterlace plugin, and the yadif and yadif2x modes from every mode list.
4. VLC patch 0048: removes FFmpeg 8.1.2 `libavcodec/aarch64/ac3dsp_init_aarch64.c` and `ac3dsp_neon.S` from the aarch64 build.
5. `SDK_MIN=27.0`.
6. iOS simulator slice: arm64.

## Upstream sources

| Part | Source | Version |
|---|---|---|
| VLCKit | https://github.com/videolan/vlckit (mirror of https://code.videolan.org/videolan/VLCKit) | tag `3.7.4`, commit `54bba6d95502d0f3f7a9da581727935b21d55fb2` |
| VLC | https://github.com/videolan/vlc (mirror of https://code.videolan.org/videolan/vlc) | commit `6de05adcbaf2e8b85fe86aad4169393098628119` (3.0.24) plus VLCKit's 42 patches in `libvlc/patches/` |
| Third-party libraries | downloaded by VLC's `contrib/` build from the URLs in `contrib/src/*/rules.mak`, checked against `contrib/src/*/SHA512SUMS` | as pinned by the VLC commit above |
| GNU make | https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz, sha256 `dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3` | 4.4.1 (build tool) |

## Build

Requirements: Apple-silicon Mac, Xcode with the iOS SDK, network access to github.com, ftp.gnu.org, download.videolan.org and code.videolan.org, about 12 GB of disk. Release built with macOS 27.0 and Xcode 27.1.

```sh
git clone https://github.com/videolan/vlckit.git vlckit
cd vlckit
git checkout 3.7.4
git am /path/to/vlckit-3.7.4-bop1.patch

git clone --branch 3.0.x https://github.com/videolan/vlc.git libvlc/vlc
git -C libvlc/vlc checkout -B localBranch 6de05adcbaf2e8b85fe86aad4169393098628119
git -C libvlc/vlc am "$PWD"/libvlc/patches/*.patch

curl -fLO https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
shasum -a 256 make-4.4.1.tar.gz     # dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3
tar xzf make-4.4.1.tar.gz
(cd make-4.4.1 && ./configure --prefix="$PWD/../libvlc/vlc/extras/tools/build" --disable-nls && make && make install)

./buildMobileVLCKit.sh -n -f
```

Output: `build/MobileVLCKit.xcframework`, slices `ios-arm64` and `ios-arm64-simulator`, dynamic frameworks with dSYMs. Package:

```sh
ditto -c -k --keepParent build/MobileVLCKit.xcframework MobileVLCKit-3.7.4-bop1.xcframework.zip
```

## Verify

For each slice (`B=build/MobileVLCKit.xcframework/<slice>/MobileVLCKit.framework/MobileVLCKit`):

```sh
nm -arch arm64 $B | grep -cE ' _vbi_|_vlc_entry__(codec_libzvbi|video_filter_rotate|misc_rtsp|stream_out_libstream_out_rtp|logger_syslog|audio_filter_channel_mixer_(dolby|mono)|control_dummy)$| _yadif'   # 0
nm -arch arm64 $B | grep -cE 'ac3dsp_init_aarch64|_ff_ac3_.*_neon|ff_float_to_fixed24_neon'                                                               # 0
nm -arch arm64 $B | grep ' _vlc_entry__codec_telx$'                                                                                                     # present
```

License scan of every source file compiled into the binary:

```sh
xcrun dwarfdump --show-sources build/MobileVLCKit.xcframework/<slice>/dSYMs/MobileVLCKit.framework.dSYM > sources.txt
python3 -I tools/gpl_scan.py sources.txt "$PWD"
```

Expected hits, all dual- or exception-licensed: 70 mbedTLS headers in librist (`Apache-2.0 OR GPL-2.0-or-later`), libgcrypt `random/rndjent.c` (BSD-3-Clause or GPL-2), VLC's `CSSGrammar.c/.h` (GPL-3+ with the Bison exception).

## Prebuilt framework

| Release | Asset | sha256 |
|---|---|---|
| `3.7.4-bop1` | `MobileVLCKit-3.7.4-bop1.xcframework.zip` | `a4e8a14ba5bdb3bd2364302058199567a378d0e28f384a37d0ac30d82166dcb9` |

## License

GNU Lesser General Public License, version 2.1 (`LICENSE`), including `tools/gpl_scan.py`.

Contact: studio@smallbricktory.com
