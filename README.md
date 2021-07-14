# Podman Dropbox

This repository provides the `dropbox` container image for running the Dropbox client on a machine with Podman.

**What is podman?**

Docker, both as a company and as a product, is deprecated. Podman is the standardized replacement for Docker which also
provides a number of essential improvements, namely rootless containers, which have the ability to run a container as a
specific user, rather than running everything as root (a bad idea!)

**Why use a container?**

The Dropbox agent for Linux is very restrictive in how it operates, with two major problems:
- Your Dropbox data must be stored in your home directory with no option to change it
- It does not operate as a normal system service (such as a systemd service unit)

Using a container allows you to work around both of these issues. Mapped volumes allow you to store your Dropbox data
wherever you wish, and podman containers can be controlled by systemd service units.

# Quick Start Guide

### 1. Prepare volumes

First, create two directories, one will be where your Dropbox data will be saved and the other will be for configuration
data.

```
mkdir /home/foo/Dropbox
mkdir /home/foo/.config/dropbox
```

**NOTE:** Dropbox **requires** that the filesystem for the Dropbox directory is ext4.
**No other filesystems are supported**. This is a limitation of Dropbox for Linux, not of this container image.

### 2. Authenticate with Dropbox

To start, you'll need to run the container in the foreground - this is needed because Dropbox will generate a unique
URL that you must use to authenticate the container with your account.

```
$ podman run --name dropbox --hostname $(hostname) -v /home/foo/Dropbox:/root/Dropbox -v /home/foo/.config/dropbox:/root/.dropbox --rm ghcr.io/ecnepsnai/dropbox:latest
[...]
This computer isn't linked to any Dropbox account...
Please visit https://www.dropbox.com/cli_link_nonce?nonce=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx to link this device.
```

*Mounts and other parameters are explained below*

Click that link and log in with your Dropbox account.

### 3. Run the container

Now that you've authenticated, you can run the container in the background, and the Dropbox agent will perform its sync
operations

```
$ podman run --name dropbox --hostname $(hostname) -v /home/foo/Dropbox:/root/Dropbox -v /home/foo/.config/dropbox:/root/.dropbox -d --rm ghcr.io/ecnepsnai/dropbox:latest
```

### 4. Check Sync Status

You can check the status of the Dropbox agent, including the progress of any sync operation, by using the provided
`dropbox` command within the container.

For example, you can use:

```
$ podman exec dropbox dropbox status
Syncing 76,722 files • 2+ days
Downloading 76,722 files (54.0 KB/sec, 2+ days)
```

# Image Options

## Volumes

The image provides two volumes:

- `/root/Dropbox` - This is the directory where your Dropbox data will be located. This **must** be mapped to an ext4
volume.
- `/root/.dropbox` - This is the directory where configuration data for the dropbox software is stored. It does not
require an ext4 volume.

It is highly recommended that you map both volumes, so that the container is truly idempotent.

## Other Parameters

It's recommended that you provide a hostname to the container using the `--hostname <VALUE>` augment. By default, podman
will use the container ID as the hostname, which may not be very helpful when trying to identify the client on your
Dropbox account.

It's also recommended that you provide a useful name for the container, such as `dropbox` (in the examples above). This
will allow for easy status checking using `podman exec`.

# License

The container & associated source files are free to use and distribute as governed by the terms of the MIT license.

Usage of the Dropbox software is subject to the terms of use and privacy policy of Dropbox itself.

This project is not associated, affiliated, or endorsed by Dropbox in any way.
