# Find original Dockerfile here: https://github.com/containers/podman/tree/main/contrib/podmanimage/stable

# Build a Podman container image from the latest
# stable version of Podman on the Fedoras Updates System.
# https://bodhi.fedoraproject.org/updates/?search=podman
# This image can be used to create a secured container
# that runs safely with privileges within the container.

FROM registry.fedoraproject.org/fedora:latest

# Add Build ARGs
ARG TARGETPLATFORM
ARG TARGETARCH
ARG DOWNLOAD_amd64="x86_64.zip"
ARG DOWNLOAD_arm64="aarch64.zip"
ARG DOWNLOAD_URL_BASE="https://awscli.amazonaws.com/awscli-exe-linux-"


# Don't include container-selinux and remove
# directories used by yum that are just taking
# up space.
RUN dnf -y update; yum -y reinstall shadow-utils; \
yum -y install curl git unzip podman fuse-overlayfs --exclude container-selinux; \
rm -rf /var/cache /var/log/dnf* /var/log/yum.*

RUN useradd podman; \
echo podman:10000:5000 > /etc/subuid; \
echo podman:10000:5000 > /etc/subgid;

VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf /etc/containers/containers.conf
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf /home/podman/.config/containers/containers.conf

RUN chown podman:podman -R /home/podman

# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock; touch /var/lib/shared/vfs-images/images.lock; touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

# Install AWS CLI v2
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    export DOWNLOAD_URL=$(echo $DOWNLOAD_URL_BASE$DOWNLOAD_amd64) ; \
    curl -sSL ${DOWNLOAD_URL} -o awscliv2.zip ; \
    unzip awscliv2.zip ; \
    ./aws/install ; \
    rm -rf aws awscliv2.zip ; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    export DOWNLOAD_URL=$(echo $DOWNLOAD_URL_BASE$DOWNLOAD_arm64) ; \
    curl -sSL ${DOWNLOAD_URL} -o awscliv2.zip ; \
    unzip awscliv2.zip ; \
    ./aws/install ; \
    rm -rf aws awscliv2.zip ; \
    fi
