#!/bin/bash

# Also check: https://github.com/JacopoPan/aerial-autonomy-stack/blob/main/supplementary/TODOs.md#maintenance-dependency-management

HELP_URL="https://github.com/JacopoPan/aerial-autonomy-stack/blob/main/supplementary/REQUIREMENTS_UBUNTU.md"
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
    echo "[INFO] WSL environment detected: some checks (NVIDIA Driver/CTK) may behave differently; open a GitHub issue, if necessary"
    HELP_URL="https://github.com/JacopoPan/aerial-autonomy-stack/blob/main/supplementary/REQUIREMENTS_WSL.md"
fi

if [ -f /etc/os-release ]; then
    source /etc/os-release
    MAJOR_VER="${VERSION_ID%%.*}"
    if [[ "$ID" == "ubuntu" && "$MAJOR_VER" -ge 22 ]]; then
        echo "[PASS] Host OS: tested with AAS (version: $PRETTY_NAME)"
    else
        echo "[WARN] Host OS: not tested with AAS (version: $PRETTY_NAME; recommended: Ubuntu 22.04 or newer)"
    fi
else
    echo "[WARN] Host OS: unknown (cannot find /etc/os-release)"
fi

if command -v nvidia-smi &> /dev/null; then
    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    DRIVER_MAJOR=${DRIVER_VER%%.*}
    if [ "$DRIVER_MAJOR" -eq 580 ] || [ "$DRIVER_MAJOR" -eq 581 ]; then
        echo "[PASS] NVIDIA Driver: tested with AAS (version: $DRIVER_VER)"
    else
        echo "[WARN] NVIDIA Driver: available but not tested with AAS (version: $DRIVER_VER; recommended: 580)"
    fi
else
    echo "[FAIL] NVIDIA Driver: not found"
    echo "    Instructions: $HELP_URL"
fi

if docker run --rm hello-world &> /dev/null; then
    DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
    DOCKER_MAJOR=${DOCKER_VER%%.*}

    if [ "$DOCKER_MAJOR" -ge 28 ]; then
        echo "[PASS] Docker Engine: tested with AAS (version: $DOCKER_VER)"
    else
        echo "[WARN] Docker Engine: available but not tested with AAS (version: $DOCKER_VER; recommended: 28 or newer)"
    fi
else
    echo "[FAIL] Docker Engine: not installed or User not in docker group for sudo-less use"
    echo "    Instructions: $HELP_URL"
fi

if docker info 2>/dev/null | grep -i "runtimes.*nvidia" &> /dev/null; then
    CTK_VER=$(nvidia-ctk --version 2>/dev/null | awk '{print $6}')
    if [ "$(printf '%s\n' "1.18" "$CTK_VER" | sort -V | head -n1)" = "1.18" ]; then
        echo "[PASS] NVIDIA Container Toolkit: tested with AAS (version: $CTK_VER)"
    else
        echo "[WARN] NVIDIA Container Toolkit: available but not tested with AAS (version: $CTK_VER; recommended: 1.18 or newer)"
    fi
else
    echo "[FAIL] NVIDIA Container Toolkit: not detected"
    echo "    Instructions: $HELP_URL"
fi
