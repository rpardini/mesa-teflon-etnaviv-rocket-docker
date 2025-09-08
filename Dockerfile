FROM debian:bookworm
# We need Python 3.10 or 3.11, since only those have prebuilt tflite-runtime wheels.
# NOT trixie: trixie has newer meson, but no python 3.11 or 3.10. So use bookworm + bookworm-backports.

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
                    libx11-xcb-dev libxshmfence-dev libxxf86vm-dev libxrandr-dev python3-pycparser
# other stuff nice to have in image
apt-get -y install bash nano tree less
# This does python 3.11 from bookworm, which is new enough for tflite-runtime 2.14.0's prebuilt wheels
apt-get -y install python3 python3-pytest python3-exceptiongroup python3-pip
# cleanup

APT_INSTALLS

# Build upstream mesa from source; enable teflon and the etnaviv and rocket drivers
RUN <<MESA_BUILD
mkdir -p /src
cd /src
git clone https://gitlab.freedesktop.org/mesa/mesa.git
cd /src/mesa
meson setup build -Dgallium-drivers=etnaviv,rocket -Dvulkan-drivers= -Dteflon=true
meson compile -C build
MESA_BUILD

RUN <<PYTHON_PIP_INSTALLS
python3 --version
python3 -m pip install --break-system-packages tflite-runtime pillow "numpy<2"
PYTHON_PIP_INSTALLS

# Create a launcher script for easy testing
RUN <<CREATE_LAUNCHER_SCRIPT
# Grab a picture of Grace for testing (should get "military uniform", "windsor tie", etc)
wget https://raw.githubusercontent.com/tensorflow/tensorflow/master/tensorflow/lite/examples/label_image/testdata/grace_hopper.bmp -O /src/mesa/grace_hopper.bmp

cat << EOD > /src/mesa/launch_teflon_test.sh
#!/bin/bash
set -e -x
cd /src/mesa
TEFLON_DEBUG=verbose ETNA_MESA_DEBUG=ml_dbgs python3 src/gallium/frontends/teflon/tests/classification.py \
    -i /src/mesa/grace_hopper.bmp \
    -m src/gallium/targets/teflon/tests/models/mobilenetv1/mobilenet_v1_1_224_quant.tflite \
    -l src/gallium/frontends/teflon/tests/labels_mobilenet_quant_v1_224.txt \
    -e build/src/gallium/targets/teflon/libteflon.so
echo "Done!"
EOD
chmod +x /src/mesa/launch_teflon_test.sh
CREATE_LAUNCHER_SCRIPT

CMD ["/src/mesa/launch_teflon_test.sh"]