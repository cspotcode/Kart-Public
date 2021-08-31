# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.191.1/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version: bionic, focal
ARG VARIANT="focal"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends build-essential git p7zip-full \
        p7zip-rar nasm libpng-dev zlib1g-dev libsdl2-dev libsdl2-mixer-dev \
        libgme-dev libopenmpt-dev libcurl4-openssl-dev cmake

RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.1.4/powershell_7.1.4-1.ubuntu.20.04_amd64.deb
RUN dpkg -i powershell_7.1.4-1.ubuntu.20.04_amd64.deb
RUN apt-get install -f -y
