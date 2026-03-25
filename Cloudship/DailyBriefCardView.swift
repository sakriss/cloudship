import UIKit

class DailyBriefCardView: UIView {
    enum State {
        case loading
        case error(String)
        case loaded(String)
    }
    
    static let padding: CGFloat = 16
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "DAILY BRIEF"
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        
        addSubview(stackView)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(summaryLabel)
        summaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        summaryLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        addSubview(spinner)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DailyBriefCardView.padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DailyBriefCardView.padding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: DailyBriefCardView.padding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DailyBriefCardView.padding),
            
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(state: State) {
        switch state {
        case .loading:
            spinner.startAnimating()
            summaryLabel.isHidden = true
        case .error:
            spinner.stopAnimating()
            summaryLabel.isHidden = true
        case .loaded(let text):
            spinner.stopAnimating()
            summaryLabel.text = text
            summaryLabel.isHidden = false
        }
    }
}

