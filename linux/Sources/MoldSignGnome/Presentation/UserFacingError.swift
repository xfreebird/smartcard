import Foundation
import MoldSignKit

enum UserFacingError {
    // MARK: - Errors (docs/09 §3.3)

    static func describe(_ error: Error) -> (message: String, recovery: String) {
        switch error {
        case CardError.wrongPIN(let remaining):
            return (L10n.text(.ui_incorrect_pin), localized(.ui_attempts_remaining_value, String(remaining)))
        case CardError.pinBlocked:
            return (L10n.text(.linux_pin_blocked), L10n.text(.ui_unblock_it_at_cev))
        case CardError.noReader:
            return (L10n.text(.ui_connect_the_reader), L10n.text(.ui_check_that_the_pcscd_service_is_running))
        case CardError.noCard:
            return (L10n.text(.ui_insert_the_card), "")
        case CardError.cardNotResponding:
            return (L10n.text(.ui_the_card_does_not_respond), L10n.text(.ui_remove_and_re_insert_the_card))
        case CardError.cardChanged:
            return (L10n.text(.linux_card_changed), L10n.text(.ui_check_the_holder_and_sign_again))
        case CardError.apduError(0x6985):
            return (L10n.text(.ui_the_card_is_in_an_invalid_state), L10n.text(.ui_remove_and_re_insert_the_card))
        case CardError.apduError(0x6988), CardError.macVerificationFailed:
            return (L10n.text(.ui_the_secure_session_was_interrupted), L10n.text(.ui_try_again))
        case CardError.signFailed(let message) where message.hasPrefix("TSA"):
            return (L10n.text(.ui_the_timestamp_service_is_not_responding), L10n.text(.ui_check_the_connection_and_try_again))
        case is TrustServices.NetworkError:
            return (L10n.text(.ui_pki_services_are_not_responding), L10n.text(.ui_check_the_connection_and_try_again))
        case let error as CocoaError where error.code == .fileWriteNoPermission || error.code == .fileWriteFileExists:
            return (L10n.text(.ui_the_signed_file_could_not_be_saved), L10n.text(.ui_choose_a_folder_you_have_permission_to_write_to))
        default:
            return (error.localizedDescription, L10n.text(.ui_try_again))
        }
    }
}
