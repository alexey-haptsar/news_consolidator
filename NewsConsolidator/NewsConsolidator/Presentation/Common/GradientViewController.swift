import UIKit

class GradientViewController: UIViewController {
    
    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupNavigationBarAppearance()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupGradient() {
        gradientLayer.colors = [
            Theme.gradientTopColor.cgColor,
            Theme.gradientBottomColor.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        view.backgroundColor = Theme.backgroundColor
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = Theme.configureNavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.accent
    }
    
    // MARK: - Error Handling
    func showError(_ error: AppError) {
        let alert = UIAlertController(
            title: error.alertTitle,
            message: error.userMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showError(_ error: Error) {
        if let appError = error as? AppError {
            showError(appError)
        } else {
            showError(AppError.unknown(underlying: error))
        }
    }
    
    func showConfirmation(title: String, message: String, confirmTitle: String = "Confirm", confirmStyle: UIAlertAction.Style = .destructive, onConfirm: @escaping () -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }
    
}
