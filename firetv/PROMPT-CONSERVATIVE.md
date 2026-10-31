# Prompt for a new Fire TV

Give this to an assistant with access to the authorized computer and TV. Replace the placeholder and add your app and feature preferences. This conservative workflow is designed to adapt the [verified Insignia example](../examples/insignia-ns-42f201na23/README.md) to a **new** TV, not to replay its package list unchanged.

---

Help me clean up and customize my Fire TV at `<TV_IP>`. Keep these apps and features: `<LIST>`. Use the conservative Insignia example for method and design, but inspect this TV independently before changing it.

1. Read this repo's Fire TV README, security guidance, launcher code, `tools/disable.ps1`, `tools/recovery.py`, and the Insignia example. Do not run `firetv/install.sh` or use the 108-package AFTALMO list as an automatic preset.
2. Connect only to the specified TV. Confirm its retail and internal model, exact firmware, installed and disabled packages, Home owner, memory and storage, TV input services, network, DNS, accessibility services, and screenshot. Use `tools/collect-baseline.ps1` with the exact values just observed, or an equivalent private backup on another OS. Keep raw dumps and screenshots out of Git.
3. Ask which streaming, casting, Alexa, antenna, HDMI, and optional Amazon features I use. Classify candidate packages on this actual TV. Keep account, original Home, Appstore, settings, remote, Wi-Fi, casting I use, TV inputs, DRM, firmware updates, and security mechanisms. Reject candidates that own Home or request TV input hardware access. Show me a short per-TV list with reasons.
4. Disable only reviewed packages, one at a time with `tools/disable.ps1 -OnlyPackage` or an equally journaled reversible method. Check Home, Wi-Fi, settings, and apps after each. Re-enable a package immediately if any function breaks. Never uninstall system packages or clear app data.
5. Build and install only My Home after reviewing the launcher source and the TV's compatibility. Configure my dock, greeting, and theme. Test manual launch and remote navigation first. Enable the Fire OS Home redirect only if supported, preserving every pre-existing accessibility service and stock Amazon Home. Test the real Home button from an app and after a reboot. If unreliable, restore the prior Home behavior.
6. Offer DNS filtering only after checking whether I use router DNS filtering or a VPN. Save and restore the exact previous DNS settings if streaming or account access is affected. Do not promise complete ad removal.
7. Record changed packages/settings/permissions, validation, remaining limitations, and a tested per-device restore plan. Reboot, verify playback and the features I use, turn ADB Debugging off, and confirm the TV is reachable while port 5555 refuses connections.

Do not publish my TV's IP, serial, account details, screenshots, raw settings, or private backup. Keep model-specific results in a new example folder, separate from other TVs' lists.
