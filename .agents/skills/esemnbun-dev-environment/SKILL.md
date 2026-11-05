---
name: esemnbun-dev-environment
description: Discover and configure a developer's eSemnBun build hosts, VM access, simulator and emulator targets without assuming the owner's machine layout.
---

# Resolve the development environment

Start with [onboarding](../../../docs/13-developer-onboarding.md). Use the ignored `.local/developer-environment.json` if supplied; [the example](../../../docs/developer-environment.example.json) defines the useful inventory fields. It is descriptive data, not commands to execute automatically.

1. Discover available local tools, SSH aliases, running simulators/emulators and configured build hosts. Read only relevant configuration; don't dump keys or credential stores.
2. Establish the transport per host: local shell, direct SSH, jump host, hypervisor forwarding, or user-driven console. Test a read-only command before transferring or building. Ask for only missing connection information that discovery cannot supply.
3. Record actual OS/architecture, repository path, SDK versions, shell and interactive-session access. A Windows SSH login is not the desktop session; launch UI through the developer's interactive-session mechanism. A headless Linux session needs its actual DISPLAY/Wayland/DBus context.
4. Confirm who owns the USB reader. Passthrough may disconnect it from the host; arrange transfer only when the task requires it. Do not reconfigure networking, enable remote desktop, create VMs or replace disks merely to match an example.
5. Transfer the relevant source at a recorded commit plus any uncommitted patch. Exclude secrets, build caches, private documents and vendor identity files from generic archives; deliver required private runtime resources separately. Never overwrite another developer's checkout without checking its state.

For the owner's existing MacBook Air/QEMU machines only, use [esemnbun-test-vms](../esemnbun-test-vms/SKILL.md). Its addresses, port forwarding, paths, accounts and historical UTM failures are one tested profile, not project prerequisites. Other developers can use physical hosts, Hyper-V, VMware, Parallels, QEMU or remote CI according to their setup.

Choose explicit iOS UDIDs and Android serials. Do not use an ambiguous `booted` or default adb target when multiple devices exist. Keep sample documents synthetic/public, or explicitly user-authorized. Environment inventory contains no passwords, PINs, tokens or private keys.
