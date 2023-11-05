//
//  CategoryContainerView.swift
//  YandexCup23
//
//  Created by Владимир Занков on 05.11.2023.
//

import UIKit

final class CategoryContainerView: UIView {
    
    var didSelect: ((String) -> Void)?
    
    private let category: Category
    
    private var categoryView: CategoryView!
    
    private var captionLabel: UILabel!
    
    init(category: Category) {
        self.category = category
        super.init(frame: .zero)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        setupView()
        setupCaptionView()
        setupCategoryView()
    }
    
    private func setupView() {
        clipsToBounds = false
    }
    
    private func setupCaptionView() {
        let label = UILabel()
        label.text = category.rawValue.lowercased()
        label.textColor = .white
        label.textAlignment = .center
        addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupCategoryView() {
        let v = CategoryView(category: category)
        addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            v.topAnchor.constraint(equalTo: topAnchor),
            v.trailingAnchor.constraint(equalTo: trailingAnchor),
            v.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        v.didSelect = { [weak self] in self?.didSelect?($0) }
        
        self.categoryView = v
    }
}

extension Category {
    var image: UIImage? {
        switch self {
        case .guitar:
            return UIImage(named: "guitarPeg")?.withAlignmentRectInsets(UIEdgeInsets(top: -15, left: 0, bottom: 5, right: 0))
        case .drums:
            return UIImage(named: "drumSticks")?.withAlignmentRectInsets(UIEdgeInsets(top: -17, left: -13, bottom: -17, right: -13))
        case .brass:
            return UIImage(named: "trumpet")?.withAlignmentRectInsets(UIEdgeInsets(top: -20, left: -7, bottom: -18, right: -9))
        case .mic:
            return nil
        }
    }
}
