# bop-vlckit

Source changes that Small Bricktory applies to VideoLAN's MobileVLCKit 3.7.4 for the iOS app Bop (published by Apexis Solutions Inc. dba Small Bricktory), so that the framework contains no GPL-licensed code. This repository provides the modified source required by the LGPL-2.1.

## Contents

- `vlckit-3.7.4-bop2.patch`: one commit on VLCKit tag `3.7.4`. bop2 = bop1 with iOS minimum 26.0.
- `vlckit-3.7.4-bop1.patch`: the earlier build, minimum iOS 27.0.
- `tools/gpl_scan.py`: license-header scanner used to check the build.
- `LICENSE`: GNU Lesser General Public License 2.1.

## Removed GPL-licensed code

1. libzvbi 0.2.45 (contains GPL-2-only files). Teletext subtitles decode through VLC's LGPL `telx` module.
2. Eight VLC modules with GPL-2+ sources: `video_filter_rotate`, `misc_rtsp`, `stream_out_libstream_out_rtp`, `logger_syslog`, `audio_filter_channel_mixer_dolby`, `audio_filter_channel_mixer_mono`, `control_dummy`, and the yadif part of `video_filter_deinterlace_libdeinterlace`.
3. yadif and yadif2x deinterlace modes (`yadif.h`, `yadif_template.h`, `algo_yadif.c/.h`), removed by VLC patch 0047. The modes auto (x), blend, mean, bob, linear, discard, phosphor and ivtc remain.
4. FFmpeg 8.1.2 `libavcodec/aarch64/ac3dsp_init_aarch64.c` and `ac3dsp_neon.S` (GPL-2+ headers), removed by VLC patch 0048. The C versions of the AC-3 DSP functions take over.

Other changes in `buildMobileVLCKit.sh`: `SDK_MIN=26.0` (bop1: 27.0), `export ASMFLAGS="${EXTRA_CFLAGS}"` (CMake-built assembly objects such as libmpg123 carry the same minimum), and the iOS simulator slice is arm64 only.

## Upstream sources

| Part | Source | Version |
|---|---|---|
| VLCKit | https://github.com/videolan/vlckit (mirror of https://code.videolan.org/videolan/VLCKit) | tag `3.7.4`, commit `54bba6d95502d0f3f7a9da581727935b21d55fb2` |
| VLC | https://github.com/videolan/vlc (mirror of https://code.videolan.org/videolan/vlc) | commit `6de05adcbaf2e8b85fe86aad4169393098628119` (3.0.24) plus VLCKit's 42 patches in `libvlc/patches/` |
| Third-party libraries | downloaded by VLC's `contrib/` build from the URLs in `contrib/src/*/rules.mak`, checked against `contrib/src/*/SHA512SUMS` | as pinned by the VLC commit above |
| GNU make | https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz, sha256 `dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3` | 4.4.1 (build tool only) |

## Build

Requirements: Apple-silicon Mac, macOS, Xcode with the iOS SDK, network access to github.com, ftp.gnu.org, download.videolan.org and code.videolan.org, about 12 GB of disk and about 20 minutes. The release was built with macOS 27.0 and Xcode 27.1.

```sh
git clone https://github.com/videolan/vlckit.git vlckit
cd vlckit
git checkout 3.7.4
git am /path/to/vlckit-3.7.4-bop2.patch

# VLC source with VLCKit's patches plus 0047 and 0048
git clone --branch 3.0.x https://github.com/videolan/vlc.git libvlc/vlc
git -C libvlc/vlc checkout -B localBranch 6de05adcbaf2e8b85fe86aad4169393098628119
git -C libvlc/vlc am "$PWD"/libvlc/patches/*.patch

# GNU make 4.4.1 into VLC's tool prefix
curl -fLO https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
shasum -a 256 make-4.4.1.tar.gz     # dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3
tar xzf make-4.4.1.tar.gz
(cd make-4.4.1 && ./configure --prefix="$PWD/../libvlc/vlc/extras/tools/build" --disable-nls && make && make install)

./buildMobileVLCKit.sh -n -f
```

`-n` skips the script's own clone-and-patch step. The result is `build/MobileVLCKit.xcframework` with slices `ios-arm64` and `ios-arm64-simulator` (dynamic frameworks, minimum iOS 26.0, dSYMs included). Package it with:

```sh
ditto -c -k --keepParent build/MobileVLCKit.xcframework MobileVLCKit-3.7.4-bop2.xcframework.zip
```

A rebuild is not bit-identical (timestamps, build paths).

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

The scan lists files whose header names the GPL without the Lesser/Library variant. The remaining hits are permissive alternatives: 70 mbedTLS headers inside librist (`Apache-2.0 OR GPL-2.0-or-later`), libgcrypt `random/rndjent.c` (BSD-3-Clause or GPL-2), and VLC's Bison-generated WebVTT CSS parser `CSSGrammar.c/.h` (GPL-3+ with the Bison exception).

## Prebuilt framework

The framework built from these sources is attached to the GitHub release `3.7.4-bop2` as `MobileVLCKit-3.7.4-bop2.xcframework.zip`.

sha256: `92cff7b1d7b6837e5983ca6ebb51869bb677e9f2adca9bb0e6171005746c36be`

Release `3.7.4-bop1` (minimum iOS 27.0, sha256 `a4e8a14ba5bdb3bd2364302058199567a378d0e28f384a37d0ac30d82166dcb9`) was built from `vlckit-3.7.4-bop1.patch`.

## License

The changes in this repository are licensed under the GNU Lesser General Public License, version 2.1 (`LICENSE`), the license of VLCKit and libVLC. The scanner script `tools/gpl_scan.py` is under the same license.

Contact: studio@smallbricktory.com
