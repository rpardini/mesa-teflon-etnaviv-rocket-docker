# Two stages: "builder" compiles Mesa (big, thrown away); the final image only has libteflon.so + the test bits.
# We need Python 3.10 or 3.11, since only those have prebuilt tflite-runtime wheels.
# NOT trixie: trixie has newer meson, but no python 3.11 or 3.10. So use bookworm + bookworm-backports.

FROM debian:bookworm AS builder

RUN <<APT_INSTALLS
# lets enable bookworm-backports so we get newer meson, required for building mesa. default release it.
echo 'deb http://deb.debian.org/debian bookworm-backports main contrib non-free' >> /etc/apt/sources.list.d/backports.list
echo 'APT::Default-Release "bookworm-backports";' > /etc/apt/apt.conf.d/99defaultrelease
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
# install all deps required for building mesa
apt-get -y install  curl wget git cmake meson python3-mako python3-yaml pkg-config libdrm-dev zlib1g-dev bison \
                    flex libwayland-dev libwayland-egl-backend-dev libxcb-dri3-dev libxcb-present-dev libxcb-sync-dev \
                    libexpat1-dev wayland-protocols libx11-dev libxext-dev libxcb-glx0-dev libxcb-shm0-dev \
                    libx11-xcb-dev libxshmfence-dev libxxf86vm-dev libxrandr-dev python3-pycparser python3
APT_INSTALLS

# Build mesa from source; defaults to upstream "main". Variants (eg rk3576) override repo/ref and apply patches/<variant>/*.patch
ARG MESA_REPO=https://gitlab.freedesktop.org/mesa/mesa.git
ARG MESA_REF=main
ARG MESA_PATCHES=
COPY patches/ /src/patches/
RUN <<MESA_BUILD
set -e
mkdir -p /src/mesa
cd /src/mesa
git init -q
git remote add origin "${MESA_REPO}"
git fetch --depth=1 origin "${MESA_REF}"
git -c advice.detachedHead=false checkout FETCH_HEAD
if [ -n "${MESA_PATCHES}" ]; then
  for p in /src/patches/${MESA_PATCHES}/*.patch; do echo "Applying ${p}"; git apply --verbose "${p}"; done
fi
echo "${MESA_REPO} ${MESA_REF} $(git rev-parse HEAD) patches=${MESA_PATCHES:-none}" | tee /src/mesa/MESA_SOURCE
meson setup build -Dgallium-drivers=etnaviv,rocket -Dvulkan-drivers= -Dteflon=true
meson compile -C build
MESA_BUILD

# Stage only what the test needs into /out, keeping the /src/mesa relative layout
RUN <<STAGE_OUTPUT
set -e
cd /src/mesa
for f in MESA_SOURCE \
         build/src/gallium/targets/teflon/libteflon.so \
         src/gallium/frontends/teflon/tests/classification.py \
         src/gallium/frontends/teflon/tests/labels_mobilenet_quant_v1_224.txt \
         src/gallium/targets/teflon/tests/models/mobilenetv1/mobilenet_v1_1_224_quant.tflite; do
  install -D "${f}" "/out/src/mesa/${f}"
done
# Grab a picture of Grace for testing (should get "military uniform", "windsor tie", etc)
wget https://raw.githubusercontent.com/tensorflow/tensorflow/master/tensorflow/lite/examples/label_image/testdata/grace_hopper.bmp -O /out/src/mesa/grace_hopper.bmp

cat << EOD > /out/src/mesa/launch_teflon_test.sh
#!/bin/bash
set -e -x
cd /src/mesa
cat /src/mesa/MESA_SOURCE
TEFLON_DEBUG=verbose ETNA_MESA_DEBUG=ml_dbgs python3 src/gallium/frontends/teflon/tests/classification.py \
    -i /src/mesa/grace_hopper.bmp \
    -m src/gallium/targets/teflon/tests/models/mobilenetv1/mobilenet_v1_1_224_quant.tflite \
    -l src/gallium/frontends/teflon/tests/labels_mobilenet_quant_v1_224.txt \
    -e build/src/gallium/targets/teflon/libteflon.so
echo "Done!"
EOD
chmod +x /out/src/mesa/launch_teflon_test.sh
STAGE_OUTPUT


FROM debian:bookworm-slim

RUN <<RUNTIME_INSTALLS
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
# libteflon.so runtime deps (libc, libdrm, libexpat, zlib), python 3.11 for tflite-runtime wheels, and some niceties
apt-get -y install --no-install-recommends libdrm2 libexpat1 zlib1g python3 python3-pip ca-certificates bash nano less
python3 -m pip install --no-cache-dir --break-system-packages tflite-runtime pillow "numpy<2"
apt-get -y purge python3-pip
apt-get -y autoremove --purge
rm -rf /var/lib/apt/lists/*
RUNTIME_INSTALLS

COPY --from=builder /out/ /

CMD ["/src/mesa/launch_teflon_test.sh"]
