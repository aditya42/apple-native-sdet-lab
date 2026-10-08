import Foundation

enum AccessibilityID {
    enum ContactList {
        static let screen = "contact.list.screen"
        static let add = "contact.add"
        static let search = "contact.search"
        static let sync = "contact.sync"
        static let loading = "contact.loading"
        static let error = "contact.error"
        static let empty = "contact.empty"
    }

    enum ContactForm {
        static let firstName = "contact.form.firstName"
        static let lastName = "contact.form.lastName"
        static let phone = "contact.form.phone"
        static let email = "contact.form.email"
        static let favorite = "contact.form.favorite"
        static let save = "contact.save"
        static let cancel = "contact.cancel"
        static let error = "contact.form.error"
    }

    enum ContactDetail {
        static let screen = "contact.detail.screen"
        static let edit = "contact.edit"
        static let delete = "contact.delete"
        static let favorite = "contact.favorite"
    }
}
