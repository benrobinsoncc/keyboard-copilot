import UIKit

final class HostViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Keyboard Copilot"
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
