from pathlib import Path
import subprocess,json,html,hashlib,textwrap
root=Path.cwd(); binary=root/'swift/MoldSignKit/.build/debug/esemnbun'
def run(args):
 p=subprocess.run([str(binary)]+args,capture_output=True,text=True);return {'args':args,'stdout':p.stdout.strip(),'stderr':p.stderr.strip(),'exit':p.returncode}
caps=run(['capabilities','--json']); verify=run(['verify','--json','swift/MoldSignKit/Tests/MoldSignKitTests/Fixtures/unsigned.pdf'])
evidence={'date':'2026-11-08','commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'binarySha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'mode':'read-only local CLI; no reader, card, PIN or credential access','observations':[caps,verify],'illustrations':'SVG terminal panels are authored command examples; only capability and unsigned-fixture panels reproduce captured output. No signing success is fabricated.'}
(root/'docs/user-guide/cli-evidence.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n')
T={
'en':{
 'title':'command-line guide','intro':'Reach a specific goal using the numbered terminal examples below. Commands stay in English. The illustrated panels are instructional examples, not screenshots of a real card signing. Only the capability and unsigned-fixture verification results were captured from a local executable; no real PIN, card or credential provider was used.',
 'need':'You need a supported electronic ID and its correct signing PIN, a compatible USB reader and any required adapter for card operations. NFC is not supported. Verification needs no reader or PIN. Keep your original documents. The private signing key stays on the card.',
 'example':'Illustrative command example. Copy the commands below; replace example paths and reader names.', 'observed':'Captured local read-only output; this is an unsigned fictional fixture, not a verified signature.',
 'install':'1. Install and discover what your executable supports','installtext':'Open [Downloads](/downloads/) and choose your platform. CLI archives contain terminal and MCP tools; the desktop application is a separate installation. Use the package-manager instructions there for the current version and signing-key fingerprint. Then locate the command and inspect capabilities before automating.',
 'installsteps':['Install through the selected platform channel.','Run capability discovery before using card commands.'],
 'reader':'2. Find the reader and check the certificate','readertext':'Connect the USB reader and insert your card. List readers, then inspect the signing certificate without entering a PIN. With several cards, use the exact reader name and check the holder before every signing request. These commands below are examples; a reader was not accessed to create this guide.',
 'readersteps':['List connected readers and card presence.','Read the intended certificate; replace the reader name.'],
 'sign':'3. Sign PDF or create an XML signature','signtext':'PDF signing embeds a PAdES-T signature and timestamp. Omitting the output path creates a separate `-semnat.pdf` file; existing outputs are not overwritten. XAdES defaults to detached XML and SHA-256: retain the unchanged original with the XML. Choose BES without timestamp, T with timestamp, or C with certificate/revocation references. Use `--enveloping` only when the recipient wants the original inside XML. Timestamped formats need network access; C also obtains status references.',
 'signsteps':['Start PDF signing and respond to the no-echo PIN prompt.','Create the XML level your recipient requires.','Use enveloping only when needed; keep originals for detached XML.'],
 'pin':'Enter the PIN only through the no-echo prompt or an existing secret-input caller with `--pin-stdin`. Input precedence is stdin, `MSIGN_PIN`, then prompt. Never put a PIN in command arguments, screenshots, scripts or logs. An incorrect PIN needs a deliberate stop and review; never retry automatically.',
 'verify':'4. Verify and interpret the result','verifytext':'Choose the signed PDF or XML. For detached XML, provide the directory containing its unchanged originals. Verification is offline: integrity, signature and embedded trust results do not establish current revocation status. `ok:true` means execution succeeded, not that the signature is valid. No recognized signature is not a successful signed-document verification.',
 'verifysteps':['Verify a PDF or XML using the original-document directory.','Use JSON for automation and inspect status, not only ok.'],
 'status':'`valid` and `unconfirmed` exit 0; the latter leaves trust unconfirmed. `invalid`, `incomplete` and `no_recognized_signature` exit 2. Missing originals alone mean incomplete, not proven modification. Exit 1 is usage/input failure; card operations use 3 wrong PIN, 4 blocked PIN, 5 no reader/card and 6 trust-service network failure. Stop after PIN errors. The app cannot unblock the card.',
 'mcp':'5. Connect an MCP host with explicit file access','mcptext':'Configure a local host that supports the implemented protocol with an absolute executable path and a trusted root you selected. Substitute your own existing physical directory. Client-advertised roots do not grant access. Symlinks, path traversal and special files are rejected. No root means discovery only. The helper uses stdio, not a network signing endpoint. Files are bounded to 8 MiB; detached XML originals need an explicitly selected detached root.',
 'mcpsteps':['Choose the installed executable and a narrow document root.','Let the host discover capabilities, then request offline verification.'],
 'mcpafter':'Use `capabilities` and `verify_document` first. Tool input identifies `{rootId,relativePath}`; never put a PIN or document contents in tool arguments. MCP verification returns minimized metadata. The host may send that metadata to its own external services. See [complete MCP setup and policy](https://esemnbun.md/packages/mcp.md) for exact protocol and host configuration.',
 'broker':'6. Request signing with foreground Mac approval','brokertext':'In the Mac app enable the agent approval broker in Settings and use its configured private spool directory. The app and helper must run as the same user. The directory and requests/responses/outputs subdirectories must already exist with mode 0700. Start the helper with that directory. In your host call prepare_signing for a PDF, review the native certificate/document request, approve with the card PIN, poll get_job and retrieve the completed output. cancel_job requests cancellation; it cannot undo a signature already in progress. Requests expire after five minutes and outputs are retained for 24 hours. Keep the app running. This is macOS-only and requires installed-build validation before relying on it.',
 'brokersteps':['Enable the Mac app broker and use its displayed private directory.','Prepare a request in the host, then approve in the app.'],
 'unattended':'7. Configure explicit unattended signing','unattendedtext':'This advanced opt-in signs without a per-document approval dialog. Provision credentials independently, pin the exact signing-certificate DER SHA-256, and create a dedicated private output directory. Use secret-provider references, never PIN values. The helper checks the card certificate before reading a secret or sending VERIFY. Physical-card/provider behavior needs validation for your installation before production use.',
 'unattendedsteps':['Set a narrow input root and private output directory.','Pin the exact certificate and choose a secret-provider reference.'],
 'lock':'Before signing, the helper creates `.unattended-signing-lock` in the output directory. Wrong PIN, interrupted execution or uncertain failure leaves this durable marker and prevents another automatic attempt. Inspect output and card outcome, reconcile deliberately, then remove the marker and restart only when appropriate. Never write an automatic lock-deletion/retry loop. A cancellation or timeout does not prove no signature was made.',
 'service':'8. Run the local browser connection','servicetext':'Run the bridge in the foreground and keep it running while using the supported site on this computer. The defaults are loopback HTTP18480 and HTTPS18443. Do not run the GUI bridge or vendor MoldSign on the same ports. Stop with Ctrl+C. The package needs its localhost HTTPS identity. Prefer the desktop app when you need native consent/PIN dialogs; a terminal bridge is not that approval UI.',
 'servicesteps':['Start the local browser bridge.','Stop with Ctrl+C when finished.'],
 'linuxprep':'On Ubuntu install `pcscd libccid`; on Fedora use `pcsc-lite pcsc-lite-ccid`. Enable `pcscd.socket`. Run card operations in a permitted local session: SSH PC/SC access may differ. CLI packages do not install the GNOME window. Linux uses glibc/OpenSSL/libcurl/PCSC; the archive is not Alpine/musl.',
 'windowslimit':'The Windows CLI currently supports help, capabilities, readers, cert, sign-hex and mcp. Normal sign/xades/verify/server/cms-for-hash commands are not implemented. Use the desktop app for those document workflows, or the separately configured MCP verification/unattended tools. Windows MCP has no foreground desktop approval broker. Do not assume command parity from the macOS/Linux examples.',
 'windowsverify':'Windows offline verification is available through MCP verify_document, not the normal verify CLI command. Launch the host with an explicit root and supply input `{rootId,relativePath}`; inspect integrity/signature/chain fields. Missing originals require the explicit detached root. No reader/PIN is used. It does not check current revocation.',
 'providers':'macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN`, or `onepassword:op://Vault/Item/field`. Linux: environment or 1Password. Windows: `credential:eSemnBun-Automation`, environment or 1Password with an explicit absolute op.exe path. A separately provisioned Keychain/Credential Manager entry must allow the intended access; the app biometric vault is not weakened. Authenticate 1Password outside MCP.',
 'advanced':'Advanced reference: macOS/Linux also expose `sign-hex <digestinfo_hex>` and `cms-for-hash <sha256_hex>`; Windows has sign-hex only. These are developer primitives, not document signing. Read the CLI contract before using them. For support include app/OS version, command without secrets, exit code and a fictional reproducer. Never attach PINs or confidential files.'},
'ro':{
 'title':'ghid pentru linia de comandă','intro':'Urmează exemplele numerotate pentru a atinge un scop concret. Comenzile rămân în engleză. Panourile ilustrează comenzi, nu o semnare reală cu un card. Doar rezultatele de capabilități și verificarea fișierului fără semnături au fost capturate local; nu a fost folosit niciun PIN, card sau furnizor de secrete real.',
 'need':'Pentru operațiuni cu cardul ai nevoie de un act electronic acceptat, PIN-ul corect, un cititor USB compatibil și adaptorul necesar. NFC nu este acceptat. Verificarea nu necesită cititor sau PIN. Păstrează originalele. Cheia privată rămâne pe card.',
 'example':'Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului.', 'observed':'Rezultat local capturat fără acces la card; fișierul fictiv nu are semnături.',
 'install':'1. Instalează și descoperă funcțiile disponibile','installtext':'Deschide [Descărcări](/downloads/) și alege platforma. Arhivele CLI conțin instrumentele de terminal și MCP; aplicația desktop se instalează separat. Folosește instrucțiunile pentru gestionarul de pachete, versiunea curentă și amprenta cheii. Localizează comanda și verifică funcțiile înainte de automatizare.',
 'installsteps':['Instalează prin canalul platformei ales.','Verifică funcțiile înainte de operațiuni cu cardul.'],
 'reader':'2. Găsește cititorul și verifică certificatul','readertext':'Conectează cititorul USB și introdu cardul. Listează cititoarele și citește certificatul fără PIN. Cu mai multe carduri, folosește numele exact al cititorului și verifică titularul înainte de semnare. Acestea sunt exemple; ghidul nu a accesat un cititor.',
 'readersteps':['Listează cititoarele și prezența cardului.','Citește certificatul dorit; înlocuiește numele cititorului.'],
 'sign':'3. Semnează PDF sau creează o semnătură XML','signtext':'PAdES-T include semnătura și marca temporală în PDF. Fără calea rezultatului se creează separat `-semnat.pdf`; rezultatele existente nu sunt suprascrise. XAdES folosește implicit XML detașat și SHA-256: păstrează originalul neschimbat împreună cu XML-ul. BES nu are marcă temporală, T are marcă temporală, C adaugă referințe de certificat/revocare. Folosește `--enveloping` doar dacă destinatarul cere originalul în XML. Formatele temporizate necesită rețea; C obține și referințe de stare.',
 'signsteps':['Pornește semnarea PDF și răspunde la solicitarea PIN fără afișare.','Creează nivelul XML cerut de destinatar.','Include originalul în XML doar la nevoie; păstrează originalele detașate.'],
 'pin':'Introdu PIN-ul doar în solicitarea fără afișare sau printr-un mecanism de intrare securizat cu `--pin-stdin`. Ordinea este stdin, `MSIGN_PIN`, apoi solicitarea. Nu pune PIN-ul în argumente, capturi, scripturi sau jurnale. După un PIN greșit oprește-te și verifică; nu reîncerca automat.',
 'verify':'4. Verifică și interpretează rezultatul','verifytext':'Alege PDF-ul sau XML-ul semnat. Pentru XML detașat, indică dosarul cu originalele neschimbate. Verificarea este offline: integritatea, semnătura și lanțul încorporat nu stabilesc starea curentă de revocare. `ok:true` înseamnă executare reușită, nu semnătură validă. Lipsa semnăturilor recunoscute nu este o verificare reușită a unui document semnat.',
 'verifysteps':['Verifică PDF sau XML cu dosarul originalelor.','Pentru automatizare citește status din JSON, nu doar ok.'],
 'status':'`valid` și `unconfirmed` au cod0; al doilea lasă încrederea neconfirmată. `invalid`, `incomplete` și `no_recognized_signature` au cod2. Lipsa originalelor indică rezultat incomplet, nu dovada modificării. Cod1: utilizare/intrare; 3: PIN greșit; 4: PIN blocat; 5: lipsă cititor/card; 6: eroare de rețea la serviciile de încredere. Oprește-te după erori PIN; aplicația nu deblochează cardul.',
 'mcp':'5. Conectează un client MCP cu acces explicit','mcptext':'Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.',
 'mcpsteps':['Alege executabilul instalat și un dosar restrâns.','Descoperă funcțiile și cere verificare offline din client.'],
 'mcpafter':'Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md).',
 'broker':'6. Cere semnare cu aprobare pe Mac','brokertext':'Activează brokerul de aprobare în Configurări pe Mac și folosește dosarul privat configurat. Aplicația și helperul trebuie să ruleze pentru același utilizator. Dosarul și subdosarele requests/responses/outputs trebuie să existe cu permisiuni0700. Pornește helperul cu acel dosar. Din client cere prepare_signing pentru PDF, verifică certificatul/documentul în aplicație, aprobă cu PIN, urmărește get_job și preia rezultatul. cancel_job cere anulare, dar nu anulează o semnătură deja creată. Cererile expiră după5minute, rezultatele se păstrează24ore. Ține aplicația pornită. Funcția există doar pe macOS și necesită validarea versiunii instalate.',
 'brokersteps':['Activează brokerul pe Mac și folosește dosarul privat afișat.','Pregătește cererea în client și aprobă în aplicație.'],
 'unattended':'7. Configurează semnarea nesupravegheată explicită','unattendedtext':'Această opțiune avansată semnează fără dialog per document. Pregătește separat secretele, fixează amprenta SHA-256 DER exactă a certificatului și creează un dosar privat pentru rezultate. Folosește referințe către furnizori, nu valori PIN. Certificatul este verificat înainte de citirea secretului sau VERIFY. Validează cardul și furnizorul în instalarea ta înainte de producție.',
 'unattendedsteps':['Configurează intrarea restrânsă și dosarul privat de rezultate.','Fixează certificatul exact și alege referința secretului.'],
 'lock':'Înainte de semnare se creează `.unattended-signing-lock` în dosarul rezultatelor. PIN-ul greșit, întreruperea sau o eroare incertă păstrează marcajul și blochează o nouă încercare automată. Verifică rezultatele și cardul, clarifică situația, apoi elimină marcajul și repornește doar când este corect. Nu automatiza ștergerea/reîncercarea. Anularea sau expirarea nu demonstrează că nu s-a semnat.',
 'service':'8. Rulează conexiunea locală cu browserul','servicetext':'Rulează bridge-ul în prim-plan cât timp folosești site-ul pe același calculator. Implicit: HTTP18480 și HTTPS18443 pe loopback. Nu porni simultan bridge-ul GUI sau MoldSign pe aceleași porturi. Oprește cu Ctrl+C. Pachetul necesită identitatea HTTPS localhost. Pentru dialoguri native de acord/PIN folosește aplicația desktop.',
 'servicesteps':['Pornește bridge-ul local pentru browser.','Oprește cu Ctrl+C la final.'],
 'linuxprep':'Pe Ubuntu instalează `pcscd libccid`; pe Fedora `pcsc-lite pcsc-lite-ccid`. Activează `pcscd.socket`. Accesul PC/SC prin SSH poate diferi de sesiunea locală. Pachetul CLI nu instalează fereastra GNOME. Arhiva folosește glibc/OpenSSL/libcurl/PCSC, nu Alpine/musl.',
 'windowslimit':'CLI Windows acceptă momentan help, capabilities, readers, cert, sign-hex și mcp. Comenzile normale sign/xades/verify/server/cms-for-hash nu sunt implementate. Pentru documente folosește aplicația desktop sau instrumentele MCP configurate separat pentru verificare/semnare nesupravegheată. MCP Windows nu are broker desktop de aprobare. Nu presupune paritate cu macOS/Linux.',
 'windowsverify':'Verificarea offline pe Windows este oferită de MCP verify_document, nu de comanda normală verify. Configurează o rădăcină explicită și intrarea `{rootId,relativePath}`; citește integritatea, semnătura și lanțul. Originalele lipsă necesită rădăcina detașată explicită. Nu se folosește cititor/PIN și nu se verifică revocarea curentă.',
 'providers':'macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` sau `onepassword:op://Vault/Item/field`. Linux: mediu sau1Password. Windows: `credential:eSemnBun-Automation`, mediu sau1Password cu o cale absolută op.exe. Intrarea Keychain/Credential Manager se pregătește separat; seiful biometric al aplicației rămâne protejat. Autentifică1Password în afara MCP.',
 'advanced':'Referință avansată: macOS/Linux oferă și `sign-hex <digestinfo_hex>`, `cms-for-hash <sha256_hex>`; Windows doar sign-hex. Sunt primitive pentru dezvoltatori, nu semnare de documente. Pentru suport trimite versiunea aplicației/sistemului, comanda fără secrete, codul și un exemplu fictiv. Nu atașa PIN sau documente confidențiale.'},
'ru':{
 'title':'руководство командной строки','intro':'Следуйте пронумерованным примерам для конкретной цели. Команды остаются на английском. Панели показывают учебные команды, а не реальную подпись картой. Только результаты возможностей и проверки неподписанного файла получены локально; настоящие PIN, карта и хранилище секретов не использовались.',
 'need':'Для операций с картой нужны поддерживаемое электронное удостоверение, правильный PIN, совместимый USB-считыватель и адаптер. NFC не поддерживается. Для проверки не нужны карта или PIN. Сохраняйте оригиналы. Закрытый ключ остаётся на карте.',
 'example':'Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя.', 'observed':'Локальный результат без обращения к карте; вымышленный файл не содержит подписей.',
 'install':'1. Установите и проверьте доступные возможности','installtext':'Откройте [Загрузки](/downloads/) и выберите платформу. Архивы CLI содержат терминальные инструменты и MCP; приложение для рабочего стола устанавливается отдельно. Используйте инструкции менеджера пакетов с актуальной версией и отпечатком ключа. Найдите команду и проверьте возможности перед автоматизацией.',
 'installsteps':['Установите через выбранный канал платформы.','Проверьте возможности перед обращением к карте.'],
 'reader':'2. Найдите считыватель и проверьте сертификат','readertext':'Подключите USB-считыватель и вставьте карту. Выведите считыватели, затем прочитайте сертификат без PIN. При нескольких картах укажите точное имя считывателя и проверьте владельца перед подписью. Это учебные команды; считыватель для руководства не использовался.',
 'readersteps':['Выведите считыватели и наличие карт.','Прочитайте нужный сертификат; замените имя считывателя.'],
 'sign':'3. Подпишите PDF или создайте XML-подпись','signtext':'PAdES-T встраивает подпись и метку времени в PDF. Без пути результата создаётся отдельный `-semnat.pdf`; существующий файл не перезаписывается. XAdES по умолчанию отделённый XML с SHA-256: храните неизменный оригинал вместе с XML. BES без метки времени, T с меткой, C с дополнительными ссылками сертификатов/отзыва. `--enveloping` нужен, когда получатель требует оригинал внутри XML. Форматам с меткой нужна сеть; C получает также сведения статуса.',
 'signsteps':['Запустите подпись PDF и введите PIN в скрытом запросе.','Создайте уровень XML, нужный получателю.','Включайте оригинал в XML только при необходимости.'],
 'pin':'Вводите PIN только в скрытом запросе или через существующий защищённый ввод с `--pin-stdin`. Приоритет: stdin, `MSIGN_PIN`, запрос. Не помещайте PIN в аргументы, снимки, скрипты или журналы. После ошибки PIN остановитесь и проверьте данные; не повторяйте автоматически.',
 'verify':'4. Проверьте документ и результат','verifytext':'Выберите подписанный PDF/XML. Для отделённого XML укажите папку с неизменными оригиналами. Проверка автономная: целостность, подпись и встроенная цепочка не устанавливают текущий статус отзыва. `ok:true` означает успешное выполнение, а не действительность подписи. Отсутствие распознанных подписей не означает успешную проверку подписанного документа.',
 'verifysteps':['Проверьте PDF/XML с папкой оригиналов.','Для автоматизации анализируйте status JSON, а не только ok.'],
 'status':'`valid` и `unconfirmed` дают код0; второй оставляет доверие неподтверждённым. `invalid`, `incomplete`, `no_recognized_signature` дают код2. Отсутствие оригиналов означает неполноту, а не доказанное изменение. Код1: ввод/использование; 3: неверный PIN; 4: PIN заблокирован; 5: нет карты/считывателя; 6: ошибка сети служб доверия. После ошибки PIN остановитесь. Приложение не разблокирует карту.',
 'mcp':'5. Подключите MCP с явным доступом к файлам','mcptext':'Настройте локальный клиент совместимого протокола с абсолютным путём программы и выбранной доверенной папкой. Укажите существующую физическую папку. Корни, заявленные клиентом, не дают прав. Символические ссылки, обход пути и специальные файлы отклоняются. Без корней доступно только обнаружение. Используется stdio, а не сетевой сервис подписи. Лимит8МиБ; оригиналам XML нужен отдельный явно указанный корень.',
 'mcpsteps':['Выберите установленную программу и ограниченную папку.','Запросите возможности, затем автономную проверку.'],
 'mcpafter':'Начните с `capabilities` и `verify_document`. Вход: `{rootId,relativePath}`; не передавайте PIN или содержимое документа. Возвращаются минимальные метаданные. Клиент может передать их своим внешним сервисам. См. [настройку и правила MCP](https://esemnbun.md/packages/mcp.md).',
 'broker':'6. Запросите подпись с подтверждением на Mac','brokertext':'Включите брокер подтверждения в Настройках приложения Mac и используйте его приватную папку. Приложение и helper должны работать от одного пользователя. Папка и requests/responses/outputs должны существовать с правами0700. Запустите helper с ней. В клиенте вызовите prepare_signing для PDF, проверьте сертификат/документ в приложении, подтвердите PIN, опрашивайте get_job и получите результат. cancel_job запрашивает отмену, но не отменяет уже созданную подпись. Запросы истекают через5минут, результаты хранятся24часа. Приложение должно работать. Только macOS; проверьте установленную сборку перед использованием.',
 'brokersteps':['Включите брокер Mac и используйте показанную приватную папку.','Подготовьте запрос в клиенте и подтвердите в приложении.'],
 'unattended':'7. Явно настройте подпись без присутствия','unattendedtext':'Этот расширенный режим подписывает без диалога на каждый документ. Отдельно подготовьте секреты, закрепите точный SHA-256 DER сертификата и создайте приватную папку результатов. Используйте ссылки на источники, а не PIN. Сертификат проверяется до чтения секрета и VERIFY. Проверьте карту и источник в своей установке до применения в работе.',
 'unattendedsteps':['Укажите ограниченный вход и приватную папку результатов.','Закрепите сертификат и выберите ссылку источника секрета.'],
 'lock':'Перед подписью создаётся `.unattended-signing-lock` в папке результатов. Неверный PIN, прерывание или неопределённая ошибка оставляют маркер и блокируют повтор. Проверьте результат и состояние карты, осознанно устраните неопределённость и только затем удалите маркер и перезапустите. Не автоматизируйте удаление/повтор. Отмена или тайм-аут не доказывают отсутствие подписи.',
 'service':'8. Запустите локальное соединение с браузером','servicetext':'Держите bridge в переднем плане во время работы с сайтом на этом компьютере. По умолчанию loopback HTTP18480 и HTTPS18443. Не запускайте GUI bridge или MoldSign на тех же портах. Остановите Ctrl+C. Пакету нужна HTTPS-идентичность localhost. Для нативных диалогов согласия/PIN используйте приложение рабочего стола.',
 'servicesteps':['Запустите локальный bridge браузера.','Завершите Ctrl+C после работы.'],
 'linuxprep':'В Ubuntu установите `pcscd libccid`; в Fedora `pcsc-lite pcsc-lite-ccid`. Включите `pcscd.socket`. Права PC/SC через SSH могут отличаться от локального сеанса. Пакет CLI не устанавливает окно GNOME. Архиву нужны glibc/OpenSSL/libcurl/PCSC; это не Alpine/musl.',
 'windowslimit':'CLI Windows сейчас поддерживает help, capabilities, readers, cert, sign-hex, mcp. Обычные sign/xades/verify/server/cms-for-hash не реализованы. Для документов используйте настольное приложение или отдельно настроенные инструменты MCP проверки/подписи без присутствия. В Windows MCP нет брокера подтверждения настольного приложения. Не предполагайте одинаковые команды с macOS/Linux.',
 'windowsverify':'Автономная проверка Windows доступна через MCP verify_document, не обычную команду verify. Настройте явный корень и `{rootId,relativePath}`; анализируйте целостность, подпись, цепочку. Для отсутствующих оригиналов нужен отдельный корень. Карта/PIN не используются; текущий отзыв не проверяется.',
 'providers':'macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` или `onepassword:op://Vault/Item/field`. Linux: окружение или1Password. Windows: `credential:eSemnBun-Automation`, окружение или1Password с абсолютным путём op.exe. Отдельно подготовленная запись Keychain/Credential Manager должна разрешать нужный доступ; биометрическое хранилище приложения не ослабляется. Войдите в1Password вне MCP.',
 'advanced':'Расширенная справка: macOS/Linux также дают `sign-hex <digestinfo_hex>` и `cms-for-hash <sha256_hex>`; Windows только sign-hex. Это инструменты разработчика, не подпись документов. Для поддержки укажите версии приложения/ОС, команду без секретов, код и вымышленный пример. Не прикладывайте PIN или конфиденциальные файлы.'}}

def svg(platform,lang,name,lines,labels):
 out=root/f'website/static/img/guide/{platform}/{lang}';out.mkdir(parents=True,exist_ok=True)
 wrapped=[]
 for line in lines:
  # preserve readable commands without making mobile assets enormous
  wrapped.extend(textwrap.wrap(line,68,replace_whitespace=False,drop_whitespace=False) or [''])
 h=95+len(wrapped)*28
 title={'en':'Command example','ro':'Exemplu de comandă','ru':'Пример команды'}[lang]
 parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="960" height="{h}" viewBox="0 0 960 {h}">',f'<rect width="960" height="{h}" rx="18" fill="#101b2c"/>','<circle cx="26" cy="26" r="6" fill="#ef7878"/><circle cx="46" cy="26" r="6" fill="#edc56a"/><circle cx="66" cy="26" r="6" fill="#6bc999"/>',f'<text x="95" y="32" font-family="sans-serif" font-size="18" fill="#b9c7dc">{html.escape(platform+" · "+title)}</text>']
 for i,line in enumerate(wrapped):
  color='#9ce0bc' if line.startswith(('$','PS>')) else '#e3ebf8'
  parts.append(f'<text x="120" y="{80+i*28}" xml:space="preserve" font-family="DejaVu Sans Mono,Menlo,Consolas,monospace" font-size="19" fill="{color}">{html.escape(line)}</text>')
 parts.append('</svg>');(out/f'{name}.svg').write_text(''.join(parts))
 return f'/img/guide/{platform}/{lang}/{name}.svg',h,len(wrapped)

def panel(platform,lang,name,commands,steps,observed=False,display=None):
 lines=display or [(('  ' if c.startswith(' ') else '$ ') if platform!='windows-cli' else ('    ' if c.startswith(' ') else 'PS> '))+c for c in commands.splitlines()]
 src,h,n=svg(platform,lang,name,lines,steps)
 coords=[]
 for i,step in enumerate(steps):
  if i >= n:
   coords.append({'text':step})
   continue
  y=(72+round(i*max(1,n-1)/max(1,len(steps)-1))*28)/h*100
  coords.append({'x':3,'y':round(y,1),'text':step})
 t=T[lang];mark=(t['observed'] if name=='unsigned' else {'en':'Captured local read-only capability output.','ro':'Rezultat local capturat: funcțiile disponibile, fără acces la card.','ru':'Локальный результат возможностей без доступа к карте.'}[lang]) if observed else t['example']
 block=f'<GuideScreenshot src="{src}" alt={json.dumps(t[name] if name in t else t["title"],ensure_ascii=False)} caption={json.dumps(mark,ensure_ascii=False)} steps={{{json.dumps(coords,ensure_ascii=False)}}} />\n\n'
 return block+'```'+('powershell' if platform=='windows-cli' else 'sh')+'\n'+commands+'\n```\n\n'

for lang,t in T.items():
 for platform,osname in [('macos-cli','macOS'),('linux-cli','Linux'),('windows-cli','Windows')]:
  win=platform=='windows-cli'; mac=platform=='macos-cli'
  folder=root/'website/docs/platforms' if lang=='en' else root/f'website/i18n/{lang}/docusaurus-plugin-content-docs/current/platforms';folder.mkdir(parents=True,exist_ok=True)
  doc=f'---\ntitle: {osname} CLI\n---\n\nimport GuideScreenshot from \'@site/src/components/GuideScreenshot\';\n\n# {osname} — {t["title"]}\n\n{t["intro"]}\n\n{t["need"]}\n\n'
  if win:doc+=':::info\n'+t['windowslimit']+'\n:::\n\n'
  doc+='## '+t['install']+'\n\n'+t['installtext']+'\n\n'
  install='brew install xfreebird/utils/esemnbun-cli\ncommand -v esemnbun\nesemnbun capabilities --json' if mac else 'scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils\nscoop install esemnbun/esemnbun-cli\nGet-Command esemnbun\nesemnbun capabilities --json' if win else 'sudo apt install esemnbun-cli\ncommand -v esemnbun\nesemnbun capabilities --json'
  if not mac and not win:doc+=t['linuxprep']+'\n\n'+('Configure the signed APT repository from Downloads before running apt install. On Fedora use dnf instead.' if lang=='en' else 'Configurează depozitul APT semnat din Descărcări înainte de apt install. Pe Fedora folosește dnf.' if lang=='ro' else 'Перед apt install настройте подписанный репозиторий APT со страницы загрузок. В Fedora используйте dnf.')+'\n\n'
  doc+=panel(platform,lang,'install',install,t['installsteps'])
  if win:
   doc+=('For Chocolatey, download the project .nupkg to an empty folder, then run:' if lang=='en' else 'Pentru Chocolatey, descarcă .nupkg într-un dosar gol, apoi execută:' if lang=='ro' else 'Для Chocolatey загрузите .nupkg проекта в пустую папку, затем выполните:')+'\n\n```powershell\nchoco install esemnbun-cli --source . --yes\n```\n\n'
  if mac:
   summary=json.loads(caps['stdout'])['data']
   doc+=panel(platform,lang,'capability','esemnbun capabilities --json',t['installsteps'][1:],True,display=['$ esemnbun capabilities --json']+json.dumps(json.loads(caps['stdout']),indent=2).splitlines())
   doc+=('The captured local build reports MCP unavailable from its ordinary CLI capability envelope; the separate installed esemnbun-mcp helper has its own discovery. Always inspect your installed binaries.' if lang=='en' else 'Versiunea locală capturată raportează MCP indisponibil în CLI normal; helperul separat esemnbun-mcp are propria descoperire. Verifică executabilele instalate.' if lang=='ro' else 'Локальная сборка сообщает недоступность MCP в обычном CLI; отдельный esemnbun-mcp имеет собственное обнаружение. Проверяйте установленные программы.')+'\n\n'
  doc+='## '+t['reader']+'\n\n'+t['readertext']+'\n\n'
  reader='esemnbun readers\nesemnbun cert --reader "miniLector EVO" --out leaf.der'
  doc+=panel(platform,lang,'reader',reader,t['readersteps'])
  if not win:
   doc+='## '+t['sign']+'\n\n'+t['signtext']+'\n\n'
   sign='esemnbun sign Contract.pdf Contract-semnat.pdf\nesemnbun xades XAdES-T Declaration.txt Declaration.xml\nesemnbun xades XAdES-BES Declaration.txt Embedded.xml --enveloping'
   doc+=panel(platform,lang,'sign',sign,t['signsteps'])+t['pin']+'\n\n```sh\nesemnbun sign Contract.pdf Contract-semnat.pdf --pin-stdin\n```\n\n'
   doc+='## '+t['verify']+'\n\n'+t['verifytext']+'\n\n'
   commands='esemnbun verify Contract-semnat.pdf\nesemnbun verify Declaration.xml /home/me/Originals\nesemnbun verify --json Contract-semnat.pdf'
   doc+=panel(platform,lang,'verify',commands,t['verifysteps'])
   if mac:
    obj=json.loads(verify['stdout'])
    obs=['$ esemnbun verify --json unsigned.pdf']+json.dumps(obj,indent=2).splitlines()
    doc+=panel(platform,lang,'unsigned','esemnbun verify --json unsigned.pdf',t['verifysteps'][1:],True,display=obs)
   doc+=t['status']+'\n\n'
  else:
   doc+='## '+t['verify']+'\n\n'+t['windowsverify']+'\n\n'
  doc+='## '+t['mcp']+'\n\n'+t['mcptext']+'\n\n'
  if win:mcp='esemnbun mcp --root "documents=C:\\Users\\me\\Documents\\Signing"'
  else:mcp='esemnbun-mcp --root documents='+('/Users/me' if mac else '/home/me')+'/Documents/Signing'
  doc+=panel(platform,lang,'mcp',mcp,t['mcpsteps'])+t['mcpafter']+'\n\n'
  host={'command':'C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe' if win else '/opt/homebrew/bin/esemnbun-mcp' if mac else '/usr/bin/esemnbun-mcp','args':(['mcp'] if win else [])+['--root','documents=C:\\Users\\me\\Documents\\Signing' if win else 'documents='+('/Users/me' if mac else '/home/me')+'/Documents/Signing']}
  # Explicitly retain copyable JSON; these are schema examples, not protocol frames.
  doc+='```json\n'+json.dumps(host,indent=2)+'\n```\n\n```json\n{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}\n```\n\n'
  if mac:
   doc+='## '+t['broker']+'\n\n'+t['brokertext']+'\n\n'
   doc+=panel(platform,lang,'broker','esemnbun-mcp --root documents=/Users/me/Documents/Signing \\\n  --broker-directory /Users/me/PrivateBroker',t['brokersteps'])
  doc+='## '+t['unattended']+'\n\n'+t['unattendedtext']+'\n\n'
  base='C:\\Users\\me' if win else '/Users/me' if mac else '/home/me'
  if win:
   unattended='esemnbun mcp `\n  --root "documents=C:\\Users\\me\\Documents\\Signing" `\n  --allow-unattended-signing `\n  --signing-certificate-sha256 <CERTIFICATE_SHA256> `\n  --signing-output-directory C:\\Users\\me\\PrivateOutput `\n  --pin-source credential:eSemnBun-Automation'
  else:
   unattended='esemnbun-mcp \\\n  --root documents='+base+'/Documents/Signing \\\n  --allow-unattended-signing \\\n  --signing-certificate-sha256 <CERTIFICATE_SHA256> \\\n  --signing-output-directory '+base+'/PrivateOutput \\\n  --pin-source '+('keychain:service:account' if mac else 'env:ESEMNBUN_AUTOMATION_PIN')
  doc+=panel(platform,lang,'unattended',unattended,t['unattendedsteps'])+t['providers']+'\n\n'
  doc+=('Replace `<CERTIFICATE_SHA256>` with the exact 64 hexadecimal digits before running. The output folder must already exist; macOS/Linux require ownership by you and mode0700. Windows allows only your account, SYSTEM and Administrators in its ACL.' if lang=='en' else 'Înlocuiește `<CERTIFICATE_SHA256>` cu64cifre hexazecimale exacte înainte de executare. Dosarul rezultat trebuie să existe; macOS/Linux cer proprietar curent și0700. ACL Windows permite doar contul tău, SYSTEM și Administrators.' if lang=='ro' else 'Перед запуском замените `<CERTIFICATE_SHA256>` точными64шестнадцатеричными цифрами. Папка должна существовать: macOS/Linux требуют владельца-пользователя и0700; ACL Windows допускает только пользователя, SYSTEM и Administrators.')+'\n\n'+t['lock']+'\n\n'
  if not win:
   doc+='## '+t['service']+'\n\n'+t['servicetext']+'\n\n'
   service='sudo systemctl enable --now pcscd.socket\nesemnbun server\n# Ctrl+C' if not mac else 'esemnbun server\n# Ctrl+C'
   doc+=panel(platform,lang,'service',service,t['servicesteps'])
  doc+='---\n\n'+t['advanced']+'\n'
  if win:
   import re
   heading_counter=iter(range(1,20))
   doc=re.sub(r'(?m)^## \d+\. ',lambda _: '## '+str(next(heading_counter))+'. ',doc)
  (folder/f'{platform}.md').write_text(doc)
