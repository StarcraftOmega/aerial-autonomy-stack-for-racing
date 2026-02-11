#!/bin/bash

if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
    echo "ℹ️  WSL environment detected: some checks (NVIDIA Driver/CTK) may behave differently; open a GitHub issue, if necessary"
fi

if [ -f /etc/os-release ]; then
    source /etc/os-release
    MAJOR_VER="${VERSION_ID%%.*}"
    if [[ "$ID" == "ubuntu" && "$MAJOR_VER" -ge 22 ]]; then
        echo "✅ Host OS: tested with AAS (version: $PRETTY_NAME)"
    else
        echo "⚠️  Host OS: not tested with AAS (version: $PRETTY_NAME; recommended: Ubuntu 22.04 or newer)"
    fi
else
    echo "⚠️  Host OS: unknown (cannot find /etc/os-release)"
fi

if command -v nvidia-smi &> /dev/null; then
    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    DRIVER_MAJOR=${DRIVER_VER%%.*}
    if [ "$DRIVER_MAJOR" -eq 580 ]; then
        echo "✅ NVIDIA Driver: tested with AAS (version: $DRIVER_VER)"
    else
        echo "⚠️  NVIDIA Driver: available but not tested with AAS (version: $DRIVER_VER; recommended: 580)"
    fi
else
    echo "❌ NVIDIA Driver: not found"
fi

if docker run --rm hello-world &> /dev/null; then
    DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
    DOCKER_MAJOR=${DOCKER_VER%%.*}

    if [ "$DOCKER_MAJOR" -ge 28 ]; then
        echo "✅ Docker Engine: tested with AAS (version: $DOCKER_VER)"
    else
        echo "⚠️  Docker Engine: available but not tested with AAS (version: $DOCKER_VER; recommended: 28 or newer)"
    fi
else
    echo "❌ Docker Engine: not installed or User not in docker group for sudo-less use"
fi

if docker info 2>/dev/null | grep -i "runtimes.*nvidia" &> /dev/null; then
    CTK_VER=$(nvidia-ctk --version 2>/dev/null | awk '{print $6}')
    if [ "$(printf '%s\n' "1.18" "$CTK_VER" | sort -V | head -n1)" = "1.18" ]; then
        echo "✅ NVIDIA Container Toolkit: tested with AAS (version: $CTK_VER)"
    else
        echo "⚠️  NVIDIA Container Toolkit: available but not tested with AAS (version: $CTK_VER; recommended: 1.18 or newer)"
    fi
else
    echo "❌ NVIDIA Container Toolkit: not detected"
fi
