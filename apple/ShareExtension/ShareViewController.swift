import UIKit
import UniformTypeIdentifiers

/// Saves shared files to the app group. iOS does not allow a share extension to
/// bring its containing app to the foreground; the user opens it after saving.
final class ShareViewController: UIViewController {
    private let groupID = "group.md.esemnbun.shared"
    private let status = UILabel()
    private let done = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        status.numberOfLines = 0
        status.textAlignment = .center
        status.text = NSLocalizedString("share_preparing", comment: "")
        done.setTitle(NSLocalizedString("share_done", comment: ""), for: .normal)
        done.isEnabled = false
        done.addTarget(self, action: #selector(close), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [status, done])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        receiveFiles()
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
                self.finish(success: true)
            } catch {
                try? FileManager.default.removeItem(at: directory)
                self.finish(success: false)
            }
        }
    }

    private func finish(success: Bool) {
        DispatchQueue.main.async {
            self.status.text = success
                ? NSLocalizedString("share_saved_open_app", comment: "")
                : NSLocalizedString("share_failed", comment: "")
            self.done.isEnabled = true
        }
    }

    @objc private func close() { extensionContext?.completeRequest(returningItems: nil) }
}
