extension DropZone {
    init(verification: Bool = false, compact: Bool = false, short: Bool = false,
         targeted: Bool = false, choose: @escaping () -> Void) {
        self.labels = DropZoneLabels(choose: L10n.text(.ui_choose_files),
            addMore: L10n.text(.ui_drop_more_documents_here_or), release: L10n.text(.ui_release_to_add),
            drop: L10n.text(.ui_drop_documents_here),
            hint: L10n.text(verification ? .ui_or_drop_it_here_signed_pdf_or_xades_signature_xml
                            : .ui_pdf_pades_t_within_the_pdf_other_files_separate_xades_t_the_format_can_be_changed))
        self.verification = verification
        self.compact = compact
        self.short = short
        self.targeted = targeted
        self.choose = choose
    }
}
