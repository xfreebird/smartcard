# eSemnBun RPM packaging (LNX-07, LNX-15): `esemnbun` (GNOME app) and `esemnbun-cli` (CLI + bridge user unit).
#
# scripts/package-linux.sh builds once, stages and runs:
#   rpmbuild -bb --nodeps --define "_topdir <dir>" --define "moldsign_version <v>" \
#            --define "moldsign_stage <staging root>" linux/packaging/rpm/esemnbun.spec
# From a checkout without a staging root, pass --define "moldsign_src <repo>" instead (swift on PATH; the
# swift.org toolchain is not an RPM, hence --nodeps when BuildRequires cannot be met).

%{!?moldsign_version: %global moldsign_version 0.2.0}
%{!?_userunitdir: %global _userunitdir %{_prefix}/lib/systemd/user}
# Prebuilt, already stripped Swift binaries (static stdlib): no debuginfo split, no brp rewrites.
%global debug_package %{nil}
%global __os_install_post %{nil}

Name:           esemnbun
Version:        %{moldsign_version}
Release:        1%{?dist}
Summary:        Sign and verify documents with the Moldovan eID card (GNOME app)
# TODO(LNX-14): the project has no LICENSE yet
License:        LicenseRef-proprietary

BuildRequires:  pkgconfig(libadwaita-1)
BuildRequires:  pkgconfig(libsecret-1)
BuildRequires:  pkgconfig(libpcsclite)
BuildRequires:  pkgconfig(openssl)
Requires:       pcsc-lite
Requires:       pcsc-lite-ccid
Requires:       pcsc-lite-libs
Requires:       libadwaita
Requires:       libsecret
Requires:       openssl-libs
Recommends:     gnome-keyring
Recommends:     xdg-desktop-portal
Suggests:       esemnbun-cli

%description
eSemnBun signs documents with the qualified certificate on the Moldovan electronic identity card
(IDEMIA CosmoX ID-A) through a USB smart-card reader, and verifies signed documents offline.
PDF documents are signed as PAdES-T (accepted by msign.gov.md), other files as detached XAdES.
It includes a browser connection compatible with the MoldSign Desktop protocol, with consent before
every signature, and can remember the PIN in the Secret Service (GNOME Keyring), per card.
The reader is reached through pcscd (CCID readers via pcsc-lite-ccid).

%package cli
Summary:        Sign and verify documents with the Moldovan eID card (command line)
Requires:       pcsc-lite
Requires:       pcsc-lite-ccid
Requires:       pcsc-lite-libs
Requires:       openssl-libs

%description cli
The esemnbun command signs PDF (PAdES-T) and other files (XAdES), verifies signatures offline,
reads the card certificate, and runs the browser bridge (MoldSign Server protocol on localhost)
for msign.gov.md. Ships the systemd user unit esemnbun-server.service, not enabled by default:
systemctl --user enable --now esemnbun-server.service

%prep

%build
%if 0%{!?moldsign_stage:1}
cd %{moldsign_src}/swift/MoldSignKit && swift build -c release --product esemnbun --static-swift-stdlib
cd %{moldsign_src}/linux && swift build -c release --static-swift-stdlib
%endif

%install
%if 0%{?moldsign_stage:1}
mkdir -p %{buildroot}
cp -a %{moldsign_stage}/. %{buildroot}/
%else
%{moldsign_src}/linux/packaging/install.sh %{buildroot} %{_prefix} all
%endif

%files
%{_bindir}/esemnbun-gnome
%{_datadir}/applications/md.moldsign.MoldSign.desktop
%{_datadir}/metainfo/md.moldsign.MoldSign.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/md.moldsign.MoldSign.svg
%{_datadir}/icons/hicolor/symbolic/apps/md.moldsign.MoldSign-symbolic.svg
%{_datadir}/moldsign/localhost.p12

%files cli
%{_bindir}/esemnbun
%{_userunitdir}/esemnbun-server.service

%changelog
* Sun Oct 25 2026 eSemnBun maintainers <packaging@esemnbun.invalid> - 0.2.0-1
- Rebrand to eSemnBun (packages esemnbun, esemnbun-cli; CLI esemnbun)
- GNOME app: identity-card face, card switcher on the card, two-state background status

* Sun Oct 25 2026 eSemnBun maintainers <packaging@esemnbun.invalid> - 0.1.0-1
- Initial packaging: GNOME app (esemnbun) and CLI with the browser bridge user unit (esemnbun-cli)
