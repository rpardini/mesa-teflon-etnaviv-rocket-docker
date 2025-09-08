# Docker image with upstream Mesa with Teflon delegate for Etnaviv and Rocket (Rockchip) NPU support

All credits to Tomeu Vizoso, who did all the real work. This is simply a Docker image with the userspace pieces to make it easier to try out.

## Why this?

Getting the userspace pieces to try it out is slightly inconvenient, as one needs:
- Recent mainline Mesa
  - To get that building, one needs a recent Meson
- Old Python 3.10 or 3.11, as Tensorflow Lite `tflite-runtime` only publishes prebuilt wheels for those versions

Thus, this Docker image, which bundles everything together, using a Bookworm base image and bookworm-backports for Meson.

Tensorflow Lite seems to be in-flux right now, so building it from source is not yet a goal, but might be in the future.

## Get appropriate hardware and kernel

You'll need either

- Board with Etnaviv NPU (All Amlogic A311D seem to have it: Khadas VIM3, LibreComputer Alta, Radxa Zero2...)
  - You need a recent (6.16+) kernel, and the board's DT needs a `&npu` node. 
    - Tomeu [already contributed the DT for Khadas VIM3 and LibreComputer Alta](https://github.com/torvalds/linux/commit/587c1c00f75565567d1f26a333a3392f7a21c28c) to mainline, they should be in 6.17+.
    - See [this for Radxa Zero 2](https://github.com/armsurvivors/armbian-build/commit/85207b7c66d189514bdd9e0d38a6ddbcf9bb889a).
  - Kernel built with `CONFIG_DRM_ETNAVIV`
- Rockchip 3588 board
  - _TODO_

## Get Docker on the board

Regular Debian Bookworm and/or Trixie should suffice.

```shell
apt-get install docker.io docker-cli
```

## Pull this image

It's quite large (~1.2Gb) so pull it separately.

```shell
docker pull ghcr.io/rpardini/mesa-teflon-etnaviv-rocket-docker:latest
```

## Run it

Run it privileged (eg, as root:)

```shell
docker run -it --privileged ghcr.io/rpardini/mesa-teflon-etnaviv-rocket-docker:latest
```

### Expected output, Etnaviv

Kernel dmesg:

```
root@radxa-zero2:~# sudo dmesg --color=always | grep -i -e etnaviv
[    4.346587] etnaviv etnaviv: bound ff100000.npu (ops gpu_ops [etnaviv])
[    4.347782] etnaviv-gpu ff100000.npu: model: GC8000, revision: 7120
[    4.353869] etnaviv-gpu ff100000.npu: etnaviv has been instantiated on a NPU, for which the UAPI is still experimental
[    4.364904] [drm] Initialized etnaviv 1.4.0 for etnaviv on minor 1
```

Running in Docker:

```
root@radxa-zero2:~# docker run -it --privileged ghcr.io/rpardini/mesa-teflon-etnaviv-rocket-docker:latest
+ cd /src/mesa
+ TEFLON_DEBUG=verbose
+ ETNA_MESA_DEBUG=ml_dbgs
+ python3 src/gallium/frontends/teflon/tests/classification.py -i /src/mesa/grace_hopper.bmp -m src/gallium/targets/teflon/tests/models/mobilenetv1/mobilenet_v1_1_224_quant.tflite -l src/gallium/frontends/teflon/tests/labels_mobilenet_quant_v1_224.txt -e build/src/gallium/targets/teflon/libteflon.so
Loading external delegate from build/src/gallium/targets/teflon/libteflon.so with args: {}
Teflon delegate: loaded etnaviv driver
idx    type ver support     inputs
================================================================================================
  0    CONV v1  supported   in: 88(u8) 8(u8) 6(i32) out: 7(u8)
  1  DWCONV v1  supported   in: 7(u8) 35(u8) 34(i32) out: 33(u8)
  2    CONV v1  supported   in: 33(u8) 38(u8) 36(i32) out: 37(u8)
  3  DWCONV v1  supported   in: 37(u8) 41(u8) 40(i32) out: 39(u8)
  4    CONV v1  supported   in: 39(u8) 44(u8) 42(i32) out: 43(u8)
  5  DWCONV v1  supported   in: 43(u8) 47(u8) 46(i32) out: 45(u8)
  6    CONV v1  supported   in: 45(u8) 50(u8) 48(i32) out: 49(u8)
  7  DWCONV v1  supported   in: 49(u8) 53(u8) 52(i32) out: 51(u8)
  8    CONV v1  supported   in: 51(u8) 56(u8) 54(i32) out: 55(u8)
  9  DWCONV v1  supported   in: 55(u8) 59(u8) 58(i32) out: 57(u8)
 10    CONV v1  supported   in: 57(u8) 62(u8) 60(i32) out: 61(u8)
 11  DWCONV v1  supported   in: 61(u8) 65(u8) 64(i32) out: 63(u8)
 12    CONV v1  supported   in: 63(u8) 68(u8) 66(i32) out: 67(u8)
 13  DWCONV v1  supported   in: 67(u8) 71(u8) 70(i32) out: 69(u8)
 14    CONV v1  supported   in: 69(u8) 74(u8) 72(i32) out: 73(u8)
 15  DWCONV v1  supported   in: 73(u8) 77(u8) 76(i32) out: 75(u8)
 16    CONV v1  supported   in: 75(u8) 80(u8) 78(i32) out: 79(u8)
 17  DWCONV v1  supported   in: 79(u8) 83(u8) 82(i32) out: 81(u8)
 18    CONV v1  supported   in: 81(u8) 86(u8) 84(i32) out: 85(u8)
 19  DWCONV v1  supported   in: 85(u8) 11(u8) 10(i32) out: 9(u8)
 20    CONV v1  supported   in: 9(u8) 14(u8) 12(i32) out: 13(u8)
 21  DWCONV v1  supported   in: 13(u8) 17(u8) 16(i32) out: 15(u8)
 22    CONV v1  supported   in: 15(u8) 20(u8) 18(i32) out: 19(u8)
 23  DWCONV v1  supported   in: 19(u8) 23(u8) 22(i32) out: 21(u8)
 24    CONV v1  supported   in: 21(u8) 26(u8) 24(i32) out: 25(u8)
 25  DWCONV v1  supported   in: 25(u8) 29(u8) 28(i32) out: 27(u8)
 26    CONV v1  supported   in: 27(u8) 32(u8) 30(i32) out: 31(u8)
 27 AVGPOOL v1  unsupported in: 31(u8) out: 0(u8)
 28    CONV v1  supported   in: 0(u8) 3(u8) 2(i32) out: 1(u8)
 29 RESHAPE v1  supported   in: 1(u8) 5(i32) out: 4(u8)
 30 SOFTMAX v1  unsupported in: 4(u8) out: 87(u8)

teflon: compiling graph: 89 tensors 27 operations
idx scale     zp has_data size
=======================================
  0 0.023528   0 no       1x1x1x1024
  1 0.166099  42 no       1x1x1x1001
  2 0.000117   0 yes      1x1x1x1001
  3 0.004987  4a yes      1001x1x1x1024
  4 0.166099  42 no       1x1x1x1001
  5 0.000000   0 yes      1x1x1x2
  6 0.000171   0 yes      1x1x1x32
  7 0.023528   0 no       1x112x112x32
  8 0.021827  97 yes      32x3x3x3
  9 0.023528   0 no       1x14x14x512
 10 0.000572   0 yes      1x1x1x512
 11 0.024329  86 yes      1x3x3x512
 12 0.000227   0 yes      1x1x1x512
 13 0.023528   0 no       1x14x14x512
 14 0.009659  63 yes      512x1x1x512
 15 0.023528   0 no       1x14x14x512
 16 0.000456   0 yes      1x1x1x512
 17 0.019367  6a yes      1x3x3x512
 18 0.000128   0 yes      1x1x1x512
 19 0.023528   0 no       1x14x14x512
 20 0.005447  99 yes      512x1x1x512
 21 0.023528   0 no       1x7x7x512
 22 0.000184   0 yes      1x1x1x512
 23 0.007836  7e yes      1x3x3x512
 24 0.000192   0 yes      1x1x1x1024
 25 0.023528   0 no       1x7x7x1024
 26 0.008179  82 yes      1024x1x1x512
 27 0.023528   0 no       1x7x7x1024
 28 0.002969   0 yes      1x1x1x1024
 29 0.126169  d3 yes      1x3x3x1024
 30 0.000425   0 yes      1x1x1x1024
 31 0.023528   0 no       1x7x7x1024
 32 0.018048  5f yes      1024x1x1x1024
 33 0.023528   0 no       1x112x112x32
 34 0.006875   0 yes      1x1x1x32
 35 0.292199  6e yes      1x3x3x32
 36 0.000716   0 yes      1x1x1x64
 37 0.023528   0 no       1x112x112x64
 38 0.030421  79 yes      64x1x1x32
 39 0.023528   0 no       1x56x56x64
 40 0.009477   0 yes      1x1x1x64
 41 0.402773  82 yes      1x3x3x64
 42 0.000356   0 yes      1x1x1x128
 43 0.023528   0 no       1x56x56x128
 44 0.015148  68 yes      128x1x1x64
 45 0.023528   0 no       1x56x56x128
 46 0.001424   0 yes      1x1x1x128
 47 0.060537  a0 yes      1x3x3x128
 48 0.000324   0 yes      1x1x1x128
 49 0.023528   0 no       1x56x56x128
 50 0.013755  5e yes      128x1x1x128
 51 0.023528   0 no       1x28x28x128
 52 0.000394   0 yes      1x1x1x128
 53 0.016758  7b yes      1x3x3x128
 54 0.000179   0 yes      1x1x1x256
 55 0.023528   0 no       1x28x28x256
 56 0.007602  97 yes      256x1x1x128
 57 0.023528   0 no       1x28x28x256
 58 0.000966   0 yes      1x1x1x256
 59 0.041055  81 yes      1x3x3x256
 60 0.000151   0 yes      1x1x1x256
 61 0.023528   0 no       1x28x28x256
 62 0.006432  7a yes      256x1x1x256
 63 0.023528   0 no       1x14x14x256
 64 0.000317   0 yes      1x1x1x256
 65 0.013461  7a yes      1x3x3x256
 66 0.000216   0 yes      1x1x1x512
 67 0.023528   0 no       1x14x14x512
 68 0.009171  6d yes      512x1x1x256
 69 0.023528   0 no       1x14x14x512
 70 0.000869   0 yes      1x1x1x512
 71 0.036935  84 yes      1x3x3x512
 72 0.000125   0 yes      1x1x1x512
 73 0.023528   0 no       1x14x14x512
 74 0.005300  8c yes      512x1x1x512
 75 0.023528   0 no       1x14x14x512
 76 0.001003   0 yes      1x1x1x512
 77 0.042610  5e yes      1x3x3x512
 78 0.000117   0 yes      1x1x1x512
 79 0.023528   0 no       1x14x14x512
 80 0.004963  7f yes      512x1x1x512
 81 0.023528   0 no       1x14x14x512
 82 0.000667   0 yes      1x1x1x512
 83 0.028359  7f yes      1x3x3x512
 84 0.000183   0 yes      1x1x1x512
 85 0.023528   0 no       1x14x14x512
 86 0.007771  59 yes      512x1x1x512
 87 0.003906   0 no       1x1x1x1001
 88 0.007812  80 no       1x224x224x3

idx type                      inputs                   outputs  operation type-specific
================================================================================================
  0 CONV   88,8,6 7
  1 DWCONV 7,35,34 33
  2 CONV   33,38,36 37
  3 DWCONV 37,41,40 39
  4 CONV   39,44,42 43
  5 DWCONV 43,47,46 45
  6 CONV   45,50,48 49
  7 DWCONV 49,53,52 51
  8 CONV   51,56,54 55
  9 DWCONV 55,59,58 57
 10 CONV   57,62,60 61
 11 DWCONV 61,65,64 63
 12 CONV   63,68,66 67
 13 DWCONV 67,71,70 69
 14 CONV   69,74,72 73
 15 DWCONV 73,77,76 75
 16 CONV   75,80,78 79
 17 DWCONV 79,83,82 81
 18 CONV   81,86,84 85
 19 DWCONV 85,11,10 9
 20 CONV   9,14,12 13
 21 DWCONV 13,17,16 15
 22 CONV   15,20,18 19
 23 DWCONV 19,23,22 21
 24 CONV   21,26,24 25
 25 DWCONV 25,29,28 27
 26 CONV   27,32,30 31

teflon: compiled graph, took 17093 ms

teflon: compiling graph: 89 tensors 2 operations
idx scale     zp has_data size
=======================================
  0 0.023528   0 no       1x1x1x1024
  1 0.166099  42 no       1x1x1x1001
  2 0.000117   0 yes      1x1x1x1001
  3 0.004987  4a yes      1001x1x1x1024
  4 0.166099  42 no       1x1x1x1001
  5 0.000000   0 yes      1x1x1x2
  6 0.000171   0 yes      1x1x1x32
  7 0.023528   0 no       1x112x112x32
  8 0.021827  97 yes      32x3x3x3
  9 0.023528   0 no       1x14x14x512
 10 0.000572   0 yes      1x1x1x512
 11 0.024329  86 yes      1x3x3x512
 12 0.000227   0 yes      1x1x1x512
 13 0.023528   0 no       1x14x14x512
 14 0.009659  63 yes      512x1x1x512
 15 0.023528   0 no       1x14x14x512
 16 0.000456   0 yes      1x1x1x512
 17 0.019367  6a yes      1x3x3x512
 18 0.000128   0 yes      1x1x1x512
 19 0.023528   0 no       1x14x14x512
 20 0.005447  99 yes      512x1x1x512
 21 0.023528   0 no       1x7x7x512
 22 0.000184   0 yes      1x1x1x512
 23 0.007836  7e yes      1x3x3x512
 24 0.000192   0 yes      1x1x1x1024
 25 0.023528   0 no       1x7x7x1024
 26 0.008179  82 yes      1024x1x1x512
 27 0.023528   0 no       1x7x7x1024
 28 0.002969   0 yes      1x1x1x1024
 29 0.126169  d3 yes      1x3x3x1024
 30 0.000425   0 yes      1x1x1x1024
 31 0.023528   0 no       1x7x7x1024
 32 0.018048  5f yes      1024x1x1x1024
 33 0.023528   0 no       1x112x112x32
 34 0.006875   0 yes      1x1x1x32
 35 0.292199  6e yes      1x3x3x32
 36 0.000716   0 yes      1x1x1x64
 37 0.023528   0 no       1x112x112x64
 38 0.030421  79 yes      64x1x1x32
 39 0.023528   0 no       1x56x56x64
 40 0.009477   0 yes      1x1x1x64
 41 0.402773  82 yes      1x3x3x64
 42 0.000356   0 yes      1x1x1x128
 43 0.023528   0 no       1x56x56x128
 44 0.015148  68 yes      128x1x1x64
 45 0.023528   0 no       1x56x56x128
 46 0.001424   0 yes      1x1x1x128
 47 0.060537  a0 yes      1x3x3x128
 48 0.000324   0 yes      1x1x1x128
 49 0.023528   0 no       1x56x56x128
 50 0.013755  5e yes      128x1x1x128
 51 0.023528   0 no       1x28x28x128
 52 0.000394   0 yes      1x1x1x128
 53 0.016758  7b yes      1x3x3x128
 54 0.000179   0 yes      1x1x1x256
 55 0.023528   0 no       1x28x28x256
 56 0.007602  97 yes      256x1x1x128
 57 0.023528   0 no       1x28x28x256
 58 0.000966   0 yes      1x1x1x256
 59 0.041055  81 yes      1x3x3x256
 60 0.000151   0 yes      1x1x1x256
 61 0.023528   0 no       1x28x28x256
 62 0.006432  7a yes      256x1x1x256
 63 0.023528   0 no       1x14x14x256
 64 0.000317   0 yes      1x1x1x256
 65 0.013461  7a yes      1x3x3x256
 66 0.000216   0 yes      1x1x1x512
 67 0.023528   0 no       1x14x14x512
 68 0.009171  6d yes      512x1x1x256
 69 0.023528   0 no       1x14x14x512
 70 0.000869   0 yes      1x1x1x512
 71 0.036935  84 yes      1x3x3x512
 72 0.000125   0 yes      1x1x1x512
 73 0.023528   0 no       1x14x14x512
 74 0.005300  8c yes      512x1x1x512
 75 0.023528   0 no       1x14x14x512
 76 0.001003   0 yes      1x1x1x512
 77 0.042610  5e yes      1x3x3x512
 78 0.000117   0 yes      1x1x1x512
 79 0.023528   0 no       1x14x14x512
 80 0.004963  7f yes      512x1x1x512
 81 0.023528   0 no       1x14x14x512
 82 0.000667   0 yes      1x1x1x512
 83 0.028359  7f yes      1x3x3x512
 84 0.000183   0 yes      1x1x1x512
 85 0.023528   0 no       1x14x14x512
 86 0.007771  59 yes      512x1x1x512
 87 0.003906   0 no       1x1x1x1001
 88 0.007812  80 no       1x224x224x3

idx type                      inputs                   outputs  operation type-specific
================================================================================================
  0 CONV   0,3,2 1
  1 RESHAPE 1,5 4

teflon: compiled graph, took 281 ms
teflon: invoked graph, took 7 ms
teflon: invoked graph, took 0 ms
teflon: invoked graph, took 7 ms
teflon: invoked graph, took 1 ms
teflon: invoked graph, took 6 ms
teflon: invoked graph, took 1 ms
teflon: invoked graph, took 6 ms
teflon: invoked graph, took 1 ms
teflon: invoked graph, took 6 ms
teflon: invoked graph, took 1 ms
0.866667: military uniform
0.031373: Windsor tie
0.015686: mortarboard
0.007843: bow tie
0.007843: academic gown
time: 7.102ms
```

### Expected output, Rocket (Rockchip)

_TODO_
