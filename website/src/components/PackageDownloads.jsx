import React from 'react';
import CodeBlock from '@theme/CodeBlock';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import packages from '../data/package-release.json';

const fingerprint='F807 5499 A4B3 11BA 30E5 3156 E562 2B86 C828 0D0B';
export default function PackageDownloads({platform}){
 const {i18n:{currentLocale}}=useDocusaurusContext();
 const text=(en,ro,ru)=>({en,ro,ru}[currentLocale]||en);
 const base=`/packages/downloads/v${packages.version}/`;
 if (!['macos','windows','linux'].includes(platform)) return null;
 return <div className="package-download-options">
   {platform === 'macos' && <details><summary>Homebrew <small>{text('CLI & MCP tools','Instrumente CLI și MCP','Инструменты CLI и MCP')}</small></summary>
    <CodeBlock language="bash">brew install xfreebird/utils/esemnbun-cli</CodeBlock>
    <a href="https://github.com/xfreebird/homebrew-utils">{text('Homebrew repository','Depozit Homebrew','Репозиторий Homebrew')}</a>
   </details>}
   {platform === 'windows' && <details><summary>Scoop / Chocolatey <small>{text('CLI & MCP tools · x64','Instrumente CLI și MCP · x64','Инструменты CLI и MCP · x64')}</small></summary>
    <h3>Scoop</h3>
    <CodeBlock language="powershell">{'scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils\nscoop install esemnbun/esemnbun-cli'}</CodeBlock>
    <h3>Chocolatey</h3>
    <p><a href={`${base}esemnbun-cli.${packages.version}.nupkg`}>{text('Download Chocolatey package','Descarcă pachetul Chocolatey','Скачать пакет Chocolatey')} · {packages.version}</a></p>
    <p>{text('Save the package in an empty folder, then run this command from that folder. This package is distributed by the project and is not listed in the Chocolatey community catalog.','Salvează pachetul într-un dosar gol, apoi execută comanda din acel dosar. Pachetul este distribuit de proiect și nu este listat în catalogul comunității Chocolatey.','Сохраните пакет в пустую папку и выполните команду из этой папки. Пакет распространяется проектом и не размещён в каталоге сообщества Chocolatey.')}</p>
    <CodeBlock language="powershell">choco install esemnbun-cli --source . --yes</CodeBlock>
   </details>}
   {platform === 'linux' && <>
   <details><summary>Ubuntu / Debian · APT <small>CLI &amp; MCP · Ubuntu 24.04+ / Debian 13+ · x86-64</small></summary>
    <CodeBlock language="bash">{'curl -fsSLo /tmp/esemnbun-signing-key.asc https://esemnbun.md/packages/signing-key.asc\ngpg --show-keys --with-fingerprint /tmp/esemnbun-signing-key.asc'}</CodeBlock>
    <p>{text('Verify the signing-key fingerprint before continuing:','Verifică amprenta cheii de semnare înainte de a continua:','Перед продолжением проверьте отпечаток ключа подписи:')} <code className="package-fingerprint">{fingerprint}</code></p>
    <CodeBlock language="bash">{`gpg --dearmor --yes --output /tmp/esemnbun.gpg /tmp/esemnbun-signing-key.asc
sudo install -m 644 /tmp/esemnbun.gpg /usr/share/keyrings/esemnbun.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/esemnbun.gpg] https://esemnbun.md/packages/apt stable main' | sudo tee /etc/apt/sources.list.d/esemnbun.list
sudo apt update
sudo apt install esemnbun-cli`}</CodeBlock>
   </details>
   <details><summary>Fedora · DNF / RPM <small>CLI &amp; MCP · x86-64</small></summary>
    <CodeBlock language="bash">{'curl -fsSLo /tmp/esemnbun.repo https://esemnbun.md/packages/esemnbun.repo\nsudo install -m 644 /tmp/esemnbun.repo /etc/yum.repos.d/esemnbun.repo\nsudo dnf install esemnbun-cli'}</CodeBlock>
    <p>{text('Confirm this fingerprint when prompted. Package and repository signatures are checked.','Confirmă această amprentă când ți se solicită. Semnăturile pachetului și ale depozitului sunt verificate.','При запросе подтвердите этот отпечаток. Проверяются подписи пакета и репозитория.')} <code className="package-fingerprint">{fingerprint}</code></p>
    <p>{text('Compatible openSUSE systems can use this RPM repository with Zypper; required libraries must be available.','Sistemele openSUSE compatibile pot folosi acest depozit RPM prin Zypper; bibliotecile necesare trebuie să fie disponibile.','Совместимые системы openSUSE могут использовать этот RPM-репозиторий через Zypper при наличии необходимых библиотек.')}</p>
   </details>
   <details><summary>{text('Arch & other Linux systems','Arch și alte sisteme Linux','Arch и другие системы Linux')} <small>CLI &amp; MCP · x86-64</small></summary>
    <p><a href="/packages/PKGBUILD">{text('Download Arch PKGBUILD','Descarcă Arch PKGBUILD','Скачать Arch PKGBUILD')}</a> — {text('inspect it, then run makepkg -si. Not listed in AUR.','verifică-l, apoi execută makepkg -si. Nu este listat în AUR.','проверьте файл, затем выполните makepkg -si. Не размещён в AUR.')}</p>
    <p><a href={`${base}esemnbun-${packages.version}-linux-x86_64.tar.gz`}>{text('Download Linux CLI archive','Descarcă arhiva CLI pentru Linux','Скачать архив CLI для Linux')} · {packages.version}</a></p>
    <p>{text('Requires compatible glibc, OpenSSL, libcurl and PC/SC libraries. Not an Alpine/musl build.','Necesită biblioteci compatibile glibc, OpenSSL, libcurl și PC/SC. Nu este o versiune pentru Alpine/musl.','Требуются совместимые библиотеки glibc, OpenSSL, libcurl и PC/SC. Не предназначено для Alpine/musl.')}</p>
   </details>
   </>}
  <p><a href="/packages/mcp.md">{text('MCP setup and signing policy','Configurarea MCP și politica de semnare','Настройка MCP и правила подписи')}</a></p>
 </div>;
}
