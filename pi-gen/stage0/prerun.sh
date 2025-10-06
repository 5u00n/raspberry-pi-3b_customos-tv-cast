#!/bin/bash -e

# Check architecture support
if command -v arch-test &>/dev/null; then
    ARCH_TEST_RESULT="$(arch-test)"
    if ! grep -q "armhf: ok" <<<"${ARCH_TEST_RESULT}"; then
        if grep -q "armhf: not supported on this machine/kernel" <<<"${ARCH_TEST_RESULT}"; then
            echo "armhf: not supported on this machine/kernel" >&2
            exit 1
        fi
        echo "Warning: armhf support may not be fully functional" >&2
    fi
fi

# Skip setarch on macOS
if [[ "$(uname)" != "Linux" ]]; then
    echo "Detected non-Linux system ($(uname)), skipping setarch"
else
    if ! setarch linux32 true 2>/dev/null; then
        echo "Warning: setarch linux32 not working, continuing anyway"
    fi
fi

if [[ "${RELEASE}" != "$(sed -n "s/\s\+//;s/^.*(\(.*\)).*$/\1/p" "${ROOTFS_DIR}/etc/os-release")" ]]; then
    echo "WARNING: RELEASE does not match the intended option for this branch."
    echo "         Please check the relevant README.md section."
fi
