//
//  CategoryView.swift
//  YandexCup23
//
//  Created by Владимир Занков on 31.10.2023.
//

import UIKit

final class CategoryView: UIView {
    
    var didSelect: ((String) -> Void)?
    
    private let category: Category
    
    private var _contentSize: CGSize = {
        let targetWidth = UIScreen.main.bounds.width / 5
        return CGSize(width: targetWidth, height: targetWidth)
    }()
    
    private var singleTapGestureRecognizer: UITapGestureRecognizer!
    private var longTapGestureRecognizer: UILongPressGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var stackView: UIStackView!
    
    private var imageView: UIImageView!
    
    private let samples: [String]
    
    private var labels: [UILabel] = []
    
    private var gLayer: CAGradientLayer!
    
    private var selectedSampleIndex = 0
    
    init(category: Category) {
        self.category = category
        self.samples = model.dict[category] ?? []
        
        super.init(frame: .zero)
        
        setupView()
        setupStackView()
        setupGlow()
        setupImageView()
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize { _contentSize }
    
    private func setupView() {
        backgroundColor = .white
        clipsToBounds = true
    }
    
    private func setupStackView() {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        for index in 0 ..< samples.count {
            let label = UILabel()
            label.text = "сэмпл \(index + 1)"
            label.isUserInteractionEnabled = true
            label.textColor = .black
            NSLayoutConstraint.activate([
                label.heightAnchor.constraint(equalToConstant: 34)
            ])
            sv.addArrangedSubview(label)
            labels.append(label)
        }
        addSubview(sv)
        sv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sv.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        self.stackView = sv
    }
    
    private func setupGlow() {
        let g = CAGradientLayer()
        g.colors = [0, 1, 1, 0].map { UIColor(white: 1, alpha: $0) }.map(\.cgColor)
        g.locations = [0, 0.25, 0.75, 1]
        g.frame = CGRect(x: 0, y: 0, width: self._contentSize.width, height: 39)
        stackView.layer.insertSublayer(g, at: 0)
        
        self.gLayer = g
    }
    
    private func setupImageView() {
        let cont = UIImageView()
        cont.image = category.image
        cont.contentMode = .scaleAspectFit
        addSubview(cont)
        cont.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cont.leadingAnchor.constraint(equalTo: leadingAnchor),
            cont.topAnchor.constraint(equalTo: topAnchor),
            cont.trailingAnchor.constraint(equalTo: trailingAnchor),
            cont.heightAnchor.constraint(equalTo: cont.widthAnchor),
            cont.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -13)
        ])
        
        self.imageView = cont
    }
    
    private func setupGestureRecognizers() {
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapGestureRecognizer.delegate = self
        addGestureRecognizer(singleTapGestureRecognizer)
        
        longTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        longTapGestureRecognizer.delegate = self
        addGestureRecognizer(longTapGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragging))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func singleTap(_ gr: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, animations: {
            guard let const = self.constraints.first(where: { $0.firstAttribute == .height }) else { return }
            const.constant += 13 + self.stackView.frame.height + 24
            self.superview?.layoutIfNeeded()
            self.superview?.superview?.subviews.forEach { $0.alpha = $0 === self.superview ? 1 : 0.5 }
            self.backgroundColor = .customFuchsia
        }) { _ in
            UIView.animate(withDuration: 0.25) {
                self._contentSize.height = self._contentSize.width
                
                self.invalidateIntrinsicContentSize()
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
                self.superview?.superview?.subviews.forEach { $0.alpha = 1 }
                self.backgroundColor = UIColor.white
            }
        }
        didSelect?(samples[0])
    }
    
    @objc func longTap(_ gr: UILongPressGestureRecognizer) {
        
        switch gr.state {
        case .began:
            UIView.animate(withDuration: 0.25, animations: {
                guard let const = self.constraints.first(where: { $0.firstAttribute == .height }) else { return }
                const.constant += 13 + self.stackView.frame.height + 24
                self.superview?.layoutIfNeeded()
                self.superview?.superview?.subviews.forEach { $0.alpha = $0 === self.superview ? 1 : 0.5 }
                self.backgroundColor = .customFuchsia
            })
        case .ended:
            UIView.animate(withDuration: 0.25) {
                self._contentSize.height = self._contentSize.width

                self.invalidateIntrinsicContentSize()
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
                self.superview?.superview?.subviews.forEach { $0.alpha = 1 }
                self.backgroundColor = UIColor.white
            }
        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if labels.count > 0 {
            gLayer.position = labels[selectedSampleIndex].layer.position
        }
        
        
        self.layer.cornerRadius = bounds.width / 2
    }
    
    @objc func dragging(_ p: UIPanGestureRecognizer) {
        guard let v = p.view else { return }
        let loc = v.convert(p.location(in: v), to: stackView)
        let l = stackView.hitTest(loc, with: nil)
        if let newIndex = labels.firstIndex(where: { $0 === l }) {
            if newIndex != selectedSampleIndex {
                let anim = CABasicAnimation(keyPath: "position")
                anim.fromValue = gLayer.position
                anim.toValue = labels[newIndex].layer.position
                gLayer.add(anim, forKey: nil)
                gLayer.position = labels[newIndex].layer.position
            }
            selectedSampleIndex = newIndex
        }
        
        
        switch p.state {
        case .began:
            break
        case .ended:
            didSelect?(samples[selectedSampleIndex])
        default:
            break
        }
    }
}

extension CategoryView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
