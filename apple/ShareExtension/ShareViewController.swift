import UIKit
import UniformTypeIdentifiers

/// Saves shared files to the app group. iOS does not allow a share extension to
/// bring its containing app to the foreground; the user opens it after saving.
final class ShareViewController: UIViewController {
    private let groupID = "group.md.esemnbun.shared"
    private let status = UILabel()
    private let detail = UILabel()
    private let symbol = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let documents = UIStackView()
    private let nextSteps = UIStackView()
    private let done = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let brand = label("eSemnBun", style: .headline)
        brand.textAlignment = .center
        symbol.image = UIImage(systemName: "square.and.arrow.down")
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        symbol.tintColor = .systemBlue
        symbol.contentMode = .scaleAspectFit
        symbol.isAccessibilityElement = false
        symbol.heightAnchor.constraint(equalToConstant: 64).isActive = true
        status.font = .preferredFont(forTextStyle: .title2)
        status.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 0
        status.textAlignment = .center
        status.accessibilityTraits = .header
        status.text = NSLocalizedString("share_preparing", comment: "")
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.numberOfLines = 0
        detail.textAlignment = .center
        detail.textColor = .secondaryLabel
        detail.text = NSLocalizedString("share_preparing_detail", comment: "")
        documents.axis = .vertical
        documents.spacing = 12
        documents.isHidden = true
        nextSteps.axis = .vertical
        nextSteps.spacing = 16
        nextSteps.isHidden = true
        nextSteps.addArrangedSubview(label(NSLocalizedString("share_next", comment: ""), style: .headline))
        for (index, key) in ["share_step_close", "share_step_open"].enumerated() {
            let number = label(String(index + 1), style: .headline)
            number.textColor = .systemBlue
            number.textAlignment = .center
            number.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
            let row = UIStackView(arrangedSubviews: [number, label(NSLocalizedString(key, comment: ""), style: .body)])
            row.spacing = 12
            row.alignment = .top
            nextSteps.addArrangedSubview(row)
        }
        spinner.startAnimating()
        let stack = UIStackView(arrangedSubviews: [brand, symbol, spinner, status, detail, documents, nextSteps])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        var configuration = UIButton.Configuration.filled()
        configuration.title = NSLocalizedString("share_done", comment: "")
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        done.configuration = configuration
        done.isEnabled = false
        done.translatesAutoresizingMaskIntoConstraints = false
        done.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(done)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: done.topAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            done.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            done.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            done.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            done.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
        isModalInPresentation = true
        receiveFiles()
    }

    private func label(_ text: String, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func receiveFiles() {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            finish(success: false); return
        }
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.data.identifier) }
        guard !providers.isEmpty else { finish(success: false); return }
        let directory = root.appendingPathComponent("ShareInbox", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        catch { finish(success: false); return }

        let queue = DispatchQueue(label: "md.esemnbun.share")
        let group = DispatchGroup()
        var failures = 0
        var savedNames: [String] = []
        for provider in providers {
            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, _ in
                defer { group.leave() }
                guard let url else { queue.sync { failures += 1 }; return }
                do {
                    // The provider's temporary URL is valid only during this callback.
                    let name = URL(fileURLWithPath: provider.suggestedName ?? url.lastPathComponent).lastPathComponent
                    var safeName = name.isEmpty || name == "." || name == ".." ? "document" : name
                    if URL(fileURLWithPath: safeName).pathExtension.isEmpty, !url.pathExtension.isEmpty {
                        safeName += "." + url.pathExtension
                    }
                    let itemDirectory = directory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                    try FileManager.default.createDirectory(at: itemDirectory, withIntermediateDirectories: true)
                    try FileManager.default.copyItem(at: url, to: itemDirectory.appendingPathComponent(safeName))
                    queue.sync { savedNames.append(safeName) }
                } catch { queue.sync { failures += 1 } }
            }
        }
        group.notify(queue: .main) {
            guard failures == 0 else {
                try? FileManager.default.removeItem(at: directory)
                self.finish(success: false); return
            }
            do {
                try Data().write(to: directory.appendingPathComponent(".ready"), options: .atomic)
                self.finish(success: true, names: savedNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
            } catch {
                try? FileManager.default.removeItem(at: directory)
                self.finish(success: false)
            }
        }
    }

    private func finish(success: Bool, names: [String] = []) {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            self.symbol.image = UIImage(systemName: success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            self.symbol.tintColor = success ? .systemGreen : .systemOrange
            self.status.text = NSLocalizedString(success ? "share_saved_title" : "share_failed_title", comment: "")
            self.detail.text = NSLocalizedString(success ? "share_saved_detail" : "share_failed", comment: "")
            self.documents.isHidden = !success
            self.nextSteps.isHidden = !success
            for name in names {
                let icon = UIImageView(image: UIImage(systemName: "doc.text"))
                icon.tintColor = .secondaryLabel
                icon.contentMode = .scaleAspectFit
                icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
                let filename = self.label(name, style: .subheadline)
                filename.lineBreakMode = .byTruncatingMiddle
                filename.numberOfLines = 2
                let row = UIStackView(arrangedSubviews: [icon, filename])
                row.spacing = 12
                row.alignment = .center
                row.isLayoutMarginsRelativeArrangement = true
                row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
                row.backgroundColor = .secondarySystemBackground
                row.layer.cornerRadius = 14
                self.documents.addArrangedSubview(row)
            }
            self.done.isEnabled = true
            self.isModalInPresentation = false
            UIAccessibility.post(notification: .screenChanged, argument: self.status)
        }
    }

    @objc private func close() { extensionContext?.completeRequest(returningItems: nil) }
}
