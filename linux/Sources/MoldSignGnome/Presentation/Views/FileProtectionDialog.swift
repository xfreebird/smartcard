import CAdwaita
import Foundation
import MoldSignKit

final class FileProtectionDialog {
    private let dialog: UnsafeMutablePointer<AdwDialog>
    private let parent: UnsafeMutablePointer<GtkWindow>
    private let processor: any PasswordFileProcessing
    private let controller: AppController
    private let form: Widget
    private let fileLabel: Widget
    private let password: Widget
    private let confirmation: Widget
    private let pin: Widget
    private let passwordGroup: Widget
    private let methodChoices: Widget
    private let passwordMethod: Widget
    private let rsaMethod: Widget
    private let publicKeyCompatibility: Widget
    private var recipientPolicy: CertificateRecipientPolicy {
        gtk_check_button_get_active(publicKeyCompatibility.cast()) != 0 ? .cardPublicKey : .encryptionCertificate
    }
    private let keySizeGroup: Widget
    private var algorithm = PasswordEncryptionAlgorithm.aes256
    private let certificateGroup: Widget
    private let recipientSummary: Widget
    private let mismatch: Widget
    private let recipient: Widget
    private let keyChoices: Widget
    private let guide: Widget
    private let help: Widget
    private let helpText: Widget
    private let details: Widget
    private let chooseCertificate: Widget
    private let methodLabel: Widget
    private let warning: Widget
    private let removeConfirmation: Widget
    private let notice: Widget
    private let run: Widget
    private let save: Widget
    private let exportCertificate: Widget
    private var operationButtons: [Widget] = []
    private var operation = 0
    private var certificateMode = false
    private var source: URL?
    private var certificate: Data?
    private var identity: CardEncryptionIdentity?
    private var reader: String?
    private var output: Data?
    private var busy = false
    private var completed = false
    private var open = true

    init(controller: AppController, parent: UnsafeMutablePointer<GtkWindow>, operation initialOperation: Int = 0, initialSource: URL? = nil, processor: any PasswordFileProcessing = PasswordFileProcessor(), preview: ProtectionPreview? = .selected, closed: @escaping () -> Void) {
        self.processor = processor
        self.controller = controller; self.parent = parent; self.operation = initialOperation
        dialog = adw_dialog_new()!
        adw_dialog_set_title(dialog, L10n.text(.protect_title))
        adw_dialog_set_content_width(dialog, 560); adw_dialog_set_content_height(dialog, 700)
        let header = adw_header_bar_new()!
        adw_header_bar_set_title_widget(header.opaque, label(L10n.text(.protect_title), classes: ["heading"]))
        form = vbox(spacing: 16); margins(form, 24)
        let encrypt = button(L10n.text(.protect_encrypt)) {}, decrypt = button(L10n.text(.protect_decrypt)) {}, remove = button(L10n.text(.protect_remove)) {}
        operationButtons = [encrypt,decrypt,remove]
        let operations=hbox(spacing:0,operationButtons);gtk_widget_add_css_class(operations,"linked");append(form,operations)
        append(form,label(L10n.text(.protect_file_step),classes:["heading"]))
        let choose = button(L10n.text(.protect_choose_file),classes:["pill"]) {}
        fileLabel = label("",wrap:true);append(form,choose);append(form,fileLabel)
        methodLabel=label(L10n.text(.protect_access_step),classes:["heading"]);append(form,methodLabel)
        passwordMethod = gtk_check_button_new_with_label(L10n.text(.protect_password))!
        rsaMethod = gtk_check_button_new_with_label(L10n.text(.protect_rsa_recipient))!
        publicKeyCompatibility = gtk_check_button_new_with_label(L10n.text(.protect_card_public_key))!
        gtk_check_button_set_group(rsaMethod.cast(), passwordMethod.cast())
        gtk_check_button_set_active(passwordMethod.cast(), 1)
        methodChoices = hbox(spacing: 16, [passwordMethod, rsaMethod])
        append(form, methodChoices)
        let keySizes = PasswordEncryptionAlgorithm.allCases.map { choice in
            gtk_check_button_new_with_label("AES-" + String(choice.rawValue))!
        }
        for option in keySizes.dropFirst() {
            gtk_check_button_set_group(option.cast(), keySizes[0].cast())
        }
        gtk_check_button_set_active(keySizes[2].cast(), 1)
        keySizeGroup = vbox(spacing: 6, [label(L10n.text(.protect_key_size)), hbox(spacing: 12, keySizes)])
        append(form, keySizeGroup)
        guide=label("",classes:["dim-label"],wrap:true);append(form,guide)
        password = gtk_password_entry_new()!;confirmation = gtk_password_entry_new()!;pin = gtk_password_entry_new()!
        for (entry,key) in [(password,L10n.Key.protect_password),(confirmation,.protect_confirm_password),(pin,.protect_card_pin)] {
            setProperty(entry,"placeholder-text",string:L10n.text(key));setAccessibleLabel(entry,L10n.text(key))
        }
        mismatch=label(L10n.text(.protect_mismatch),classes:["error"],wrap:true)
        passwordGroup = vbox(spacing:12,[password,confirmation,mismatch])
        append(form,passwordGroup)
        chooseCertificate = button(L10n.text(.protect_choose_certificate)) {}
        let readCard = button(L10n.text(.protect_read_card)) {}
        recipientSummary=label("",wrap:true)
        recipient = label("",wrap:true,selectable:true);keyChoices = vbox(spacing:6)
        exportCertificate = button(L10n.text(.protect_export_certificate)) {}
        details=gtk_expander_new(L10n.text(.protect_details))!
        gtk_expander_set_child(details.opaque,vbox(spacing:12,[recipient,exportCertificate,label(L10n.text(.protect_export_certificate_hint),classes:["caption"],wrap:true)]))
        certificateGroup = vbox(spacing:12,[publicKeyCompatibility,chooseCertificate,readCard,keyChoices,recipientSummary,details,pin]);append(form,certificateGroup)
        help=gtk_expander_new(L10n.text(.protect_help))!;helpText=label("",wrap:true)
        gtk_expander_set_child(help.opaque,helpText);append(form,help)
        warning = label("",classes:["dim-label"],wrap:true);append(form,warning)
        removeConfirmation = gtk_check_button_new_with_label(L10n.text(.protect_remove_confirm))!
        notice = label("",wrap:true);append(form,notice)
        run = button(L10n.text(.protect_encrypt),classes:["suggested-action","pill"]) {};save = button(L10n.text(.protect_save_file),classes:["suggested-action","pill"]) {}
        let actions=vbox(spacing:8,[removeConfirmation,run,save]);margins(actions,16)
        let toolbar = adw_toolbar_view_new()!
        adw_toolbar_view_add_top_bar(toolbar.opaque,header);adw_toolbar_view_add_bottom_bar(toolbar.opaque,actions);adw_toolbar_view_set_content(toolbar.opaque,scrolledPage(form));adw_dialog_set_child(dialog,toolbar)
        onSignal(exportCertificate,"clicked") { [weak self] in
            guard let self,let identity=self.identity else{return}
            self.saveData(identity.certificate,name:"certificate-\(identity.fingerprint).cer",clearOutput:false)
        }
        onSignal(dialog,"closed") { [weak self] in self?.open=false;self?.clearSecrets();self?.output=nil;closed() }
        for (button,index) in [(encrypt,0),(decrypt,1),(remove,2)] {
            onSignal(button,"clicked") { [weak self] in
                guard let self else{return};self.operation=index;self.reset();self.clearRecipient();self.clearSecrets();gtk_check_button_set_active(self.removeConfirmation.cast(),0);self.detectMethod();self.refresh()
            }
        }
        for (option, choice) in zip(keySizes, PasswordEncryptionAlgorithm.allCases) {
            onSignal(option, "toggled") { [weak self] in
                guard gtk_check_button_get_active(option.cast()) != 0 else { return }
                self?.algorithm = choice
                self?.reset()
                self?.refresh()
            }
        }
        onSignal(rsaMethod, "toggled") { [weak self] in
            guard let self else { return }
            self.certificateMode = gtk_check_button_get_active(self.rsaMethod.cast()) != 0
            self.clearRecipient()
            self.clearSecrets()
            self.reset()
            self.refresh()
        }
        onSignal(publicKeyCompatibility,"toggled") { [weak self] in
            guard let self else{return};self.clearRecipient();self.clearSecrets();self.reset();self.refresh()
        }
        for entry in [password,confirmation,pin] {onSignal(entry,"changed") {[weak self] in if self?.busy == false { self?.reset() };self?.refresh()}}
        onSignal(removeConfirmation,"toggled") { [weak self] in self?.refresh() }
        onSignal(choose,"clicked") { [weak self] in
            chooseFiles(parent:parent,title:L10n.text(.protect_choose_file),multiple:false) { paths in
                guard let self,let path=paths.first,self.open else{return};self.source=URL(fileURLWithPath:path)
                gtk_label_set_text(self.fileLabel.opaque,self.source!.lastPathComponent);self.reset();gtk_check_button_set_active(self.removeConfirmation.cast(),0);self.detectMethod();self.refresh()
            }
        }
        onSignal(self.chooseCertificate,"clicked") { [weak self] in
            chooseFiles(parent:parent,title:L10n.text(.protect_choose_certificate),multiple:false) { paths in
                guard let self,let path=paths.first,self.open else{return}
                self.setBusy(true);self.reset();self.clearRecipient()
                let policy=self.recipientPolicy
                DispatchQueue.global(qos:.userInitiated).async {
                    let result=Result {let bytes=try ProtectedFileIO.read(URL(fileURLWithPath:path));try CertificateFileProtection.validateRecipient(bytes,policy:policy);return bytes}
                    onMain { guard self.open else{return};self.setBusy(false)
                        switch result {case .success(let bytes):self.certificate=bytes;self.identity=nil;clearBox(self.keyChoices);gtk_label_set_text(self.recipientSummary.opaque,URL(fileURLWithPath:path).lastPathComponent);gtk_label_set_text(self.recipient.opaque,URL(fileURLWithPath:path).lastPathComponent)
                        case .failure:self.error()};self.refresh()
                    }
                }
            }
        }
        onSignal(readCard,"clicked") { [weak self] in self?.readCard() }
        onSignal(run,"clicked") { [weak self] in
            guard let self else { return }
            if self.completed { _ = adw_dialog_close(self.dialog) } else { self.process() }
        }
        onSignal(save,"clicked") { [weak self] in self?.saveOutput() }
        if controller.isDemo, let preview {
            operation = preview.operation
            certificateMode = false
            gtk_label_set_text(fileLabel.opaque, preview.filename)
        }
        if let initialSource, FileManager.default.fileExists(atPath: initialSource.path) {
            source = initialSource
            gtk_label_set_text(fileLabel.opaque, initialSource.lastPathComponent)
        }
        detectMethod()
        refresh();adw_dialog_present(dialog,parent.widget)
    }
    private func detectMethod() {
        guard operation == 1, let source else { return }
        setBusy(true)
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try ProtectedFileIO.usesRecipientCertificate(source) }
            onMain {
                guard self.open else { return }
                self.setBusy(false)
                switch result {
                case .success(let isRSA):
                    gtk_check_button_set_active((isRSA ? self.rsaMethod : self.passwordMethod).cast(), 1)
                case .failure:
                    self.error()
                }
                self.refresh()
            }
        }
    }

    private func text(_ entry: Widget) -> String {String(cString:gtk_editable_get_text(entry.opaque))}
    private func clearSecrets(){for entry in [password,confirmation,pin]{gtk_editable_set_text(entry.opaque,"")}}
    private func clearRecipient(){identity=nil;certificate=nil;reader=nil;clearBox(keyChoices);gtk_label_set_text(recipient.opaque,"");gtk_label_set_text(recipientSummary.opaque,"");gtk_editable_set_text(pin.opaque,"")}
    private func reset(){completed=false;output=nil;gtk_label_set_text(notice.opaque,"")}
    private func error(){gtk_label_set_text(notice.opaque,L10n.text(.protect_error))}
    private func setBusy(_ value:Bool){busy=value;gtk_widget_set_sensitive(form,value ? 0:1);adw_dialog_set_can_close(dialog,value ? 0:1);refresh()}
    private func refresh(){
        for (index,button) in operationButtons.enumerated() {
            if index==operation {gtk_widget_add_css_class(button,"suggested-action")} else {gtk_widget_remove_css_class(button,"suggested-action")}
        }
        gtk_widget_set_visible(methodChoices, operation == 2 ? 0 : 1)
        gtk_widget_set_visible(keySizeGroup, operation == 0 && !certificateMode ? 1 : 0)
        gtk_widget_set_visible(chooseCertificate,operation==0 ? 1:0)
        gtk_widget_set_visible(methodLabel,operation==2 ? 0:1)
        gtk_widget_set_visible(guide,operation==2 ? 0:1);gtk_widget_set_visible(help,operation==2 ? 0:1)
        let compatibility=certificateMode && recipientPolicy == .cardPublicKey
        let guideKey:L10n.Key=compatibility ? .protect_card_public_key_help : certificateMode ? (operation==0 ? .protect_certificate_encrypt_guide:.protect_certificate_decrypt_guide) : (operation==0 ? .protect_password_encrypt_guide:.protect_password_decrypt_guide)
        let helpKey:L10n.Key=compatibility ? .protect_card_public_key_help : certificateMode ? (operation==0 ? .protect_certificate_encrypt_help:.protect_certificate_decrypt_help) : (operation==0 ? .protect_password_encrypt_help:.protect_password_decrypt_help)
        let guidance = operation == 1 ? L10n.text(.protect_detect_algorithm) + " " + L10n.text(guideKey) : L10n.text(guideKey)
        gtk_label_set_text(guide.opaque, guidance)
        gtk_label_set_text(helpText.opaque,L10n.text(helpKey)+"\n\n"+L10n.text(.protect_compatibility))
        gtk_widget_set_visible(details,certificate == nil ? 0:1)
        gtk_widget_set_visible(recipientSummary,certificate == nil ? 0:1)
        gtk_widget_set_visible(mismatch,operation==0 && !text(confirmation).isEmpty && text(password) != text(confirmation) ? 1:0)
        gtk_widget_set_visible(passwordGroup,!certificateMode && operation != 2 ? 1:0)
        gtk_widget_set_visible(confirmation,operation==0 ? 1:0)
        gtk_widget_set_visible(certificateGroup,certificateMode && operation != 2 ? 1:0)
        gtk_widget_set_visible(exportCertificate,identity == nil ? 0:1)
        gtk_button_set_label(exportCertificate.cast(),L10n.text(compatibility ? .protect_export_public_certificate:.protect_export_certificate))
        gtk_widget_set_sensitive(exportCertificate,busy ? 0:1)
        gtk_widget_set_visible(pin,operation==1 && identity != nil ? 1:0)
        gtk_widget_set_visible(removeConfirmation,operation==2 ? 1:0)
        gtk_label_set_text(warning.opaque,L10n.text(operation==2 ? .protect_removal_warning:.protect_original))
        if operation==2 {gtk_widget_remove_css_class(run,"suggested-action");gtk_widget_add_css_class(run,"destructive-action")}
        else {gtk_widget_remove_css_class(run,"destructive-action");gtk_widget_add_css_class(run,"suggested-action")}
        gtk_button_set_label(run.cast(),L10n.text(completed ? .saved_close : operation==0 ? .protect_encrypt:operation==1 ? .protect_decrypt:.protect_remove))
        let ready = source != nil && !busy && (operation==2 ? gtk_check_button_get_active(removeConfirmation.cast()) != 0 : certificateMode ? (operation==0 ? certificate != nil : identity != nil && !text(pin).isEmpty) : !text(password).isEmpty && (operation==1 || text(password)==text(confirmation)))
        gtk_widget_set_sensitive(save,busy ? 0:1);gtk_widget_set_sensitive(run,(completed && !busy) || ready ? 1:0);gtk_widget_set_visible(run,output==nil ? 1:0);gtk_widget_set_visible(save,output==nil ? 0:1)
    }
    private func readCard(){
        guard !controller.isDemo, let reader=controller.selectedCard?.reader else{error();return}
        let policy=recipientPolicy,preferred=controller.selectedReaderName,expectedCertificate=controller.selectedCard?.certificate?.der
        clearRecipient();self.reader=reader;reset();setBusy(true)
        DispatchQueue.global(qos:.userInitiated).async {
            let result=Result {try self.controller.service.withCard(reader:reader){try $0.encryptionIdentities(policy:policy)}}
            onMain {guard self.open else{return};self.setBusy(false);clearBox(self.keyChoices)
                guard self.controller.selectedReaderName==preferred else{self.clearRecipient();self.refresh();return}
                if let current=self.controller.selectedCard {
                    guard current.reader==reader else{self.clearRecipient();self.refresh();return}
                    if let expectedCertificate,let actual=current.certificate?.der,actual != expectedCertificate {self.clearRecipient();self.refresh();return}
                }
                switch result {
                case .success(let identities):
                    if identities.isEmpty{gtk_label_set_text(self.notice.opaque,L10n.text(.protect_no_key));self.identity=nil;self.certificate=nil}
                    for identity in identities where identities.count > 1 {
                        let choose=button(identity.label+" · "+identity.fingerprint.suffix(8)) { [weak self] in self?.select(identity) }
                        append(self.keyChoices,choose)
                    }
                    if let first=identities.first{self.select(first)}
                case .failure:self.error()
                };self.refresh()
            }
        }
    }
    private func select(_ identity:CardEncryptionIdentity){self.identity=identity;certificate=identity.certificate;gtk_label_set_text(recipientSummary.opaque,identity.label);gtk_label_set_text(recipient.opaque,identity.label+"\n"+identity.fingerprint);gtk_editable_set_text(pin.opaque,"");reset();refresh()}
    private func process(){
        guard let source else{return}
        let operation=operation,algorithm=algorithm,certificateMode=certificateMode,password=text(password),pin=text(pin),certificate=certificate,identity=identity,reader=reader,policy=recipientPolicy
        reset();setBusy(true);clearSecrets()
        DispatchQueue.global(qos:.userInitiated).async {
            let result=Result<Data?,Error> {
                if !certificateMode || operation == 2 {
                    let action: FileProtectionOperation = operation == 0 ? .encryptPassword(algorithm) : operation == 1 ? .decrypt : .remove
                    return try self.processor.process(source, operation: action, password: password)
                }
                let bytes=try ProtectedFileIO.read(source)
                if operation==0,let certificate{return try CertificateFileProtection.encrypt(bytes,certificate:certificate,policy:policy)}
                guard let identity else{throw FileProtectionError.cannotDecrypt}
                return try self.controller.service.withCard(reader:reader){try $0.decryptFile(bytes,identity:identity,pin:pin)}
            }
            onMain {guard self.open else{return};self.setBusy(false)
                switch result {case .success(let output):self.output=output;gtk_label_set_text(self.notice.opaque,L10n.text(operation==2 ? .protect_removed:.protect_ready));if operation==2{self.completed=true;self.source=nil;gtk_label_set_text(self.fileLabel.opaque,"")}
                case .failure:self.error()};self.refresh()
            }
        }
    }
    private func saveOutput(){
        guard let output,let source else{return}
        var name=source.lastPathComponent
        if operation==0{name += certificateMode ? CertificateFileProtection.suffix:PasswordFileProtection.suffix}
        else{for suffix in [PasswordFileProtection.suffix,CertificateFileProtection.suffix] where name.hasSuffix(suffix){name=String(name.dropLast(suffix.count))};name="decrypted-"+name}
        saveData(output,name:name,clearOutput:true)
    }
    private func saveData(_ output:Data,name:String,clearOutput:Bool){
        let chooser=gtk_file_dialog_new();gtk_file_dialog_set_title(chooser,L10n.text(.protect_save_file));gtk_file_dialog_set_initial_name(chooser,name)
        let (callback,data)=asyncReady { [weak self] result in
            var error:UnsafeMutablePointer<GError>?
            defer{_ = takeError(error);g_object_unref(chooser?.raw)}
            guard let file=gtk_file_dialog_save_finish(chooser,result,&error) else{return}
            defer{g_object_unref(file.raw)}
            guard let path=filePath(file),let self,self.open else{return}
            self.setBusy(true)
            DispatchQueue.global(qos:.userInitiated).async {
                let result=Result{try ProtectedFileIO.saveNew(output,to:URL(fileURLWithPath:path))}
                onMain{guard self.open else{return};self.setBusy(false);switch result{case .success:if clearOutput{self.output=nil;self.completed=true;self.controller.recordProtectionOutput(path:path,encrypted:self.operation==0)};gtk_label_set_text(self.notice.opaque,L10n.text(.protect_saved));case .failure:self.error()};self.refresh()}
            }
        }
        gtk_file_dialog_save(chooser,parent,nil,callback,data)
    }
}
