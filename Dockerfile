FROM fedora:latest
LABEL maintainer="Ian Spence <ian@ecn.io>"
LABEL org.opencontainers.image.authors="Ian Spence <ian@ecn.io>"
LABEL org.opencontainers.image.source=https://github.com/ecnepsnai/podman-dropbox
LABEL org.opencontainers.image.title="dropbox"
LABEL org.opencontainers.image.description="The Dropbox client, compatible with podman and rootless containers"
LABEL org.opencontainers.image.licenses="MIT"

# Update and install required libraries
RUN dnf -y update && \
    dnf -y install gpg mesa-libglapi libXext libXdamage libxshmfence libXxf86vm patch procps-ng

# Download the dropbox setup python script
WORKDIR /root
RUN curl https://linux.dropbox.com/packages/dropbox.py > setup.py

# Apply a patch that auto-accepts any questions from the script
ADD setup.patch /root
RUN patch setup.py < setup.patch && rm setup.patch

# Add a convience 'dropbox' command that calls the helper python script
RUN echo '#!/bin/bash' > /bin/dropbox && \
    echo 'python3 /root/setup.py $@' >> /bin/dropbox && \
    chmod +x /bin/dropbox

VOLUME /root/Dropbox
VOLUME /root/.dropbox

WORKDIR /
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
