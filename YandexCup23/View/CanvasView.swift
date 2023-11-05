//
//  CanvasView.swift
//  YandexCup23
//
//  Created by Владимир Занков on 31.10.2023.
//

import UIKit

final class CanvasView: UIView {
    
    var didChangeVolume: ((Float) -> Void)?
    
    var didChangeSpeed: ((Float) -> Void)?
    
    private var backgroundLayer: CAGradientLayer!
    
    private var verticalSlider: UIView!
    private var horizontalSlider: UIView!
    
    private var verticalConstraint: NSLayoutConstraint!
    private var horizontalConstraint: NSLayoutConstraint!
    
    private var decided = false
    private var isHorizontalDirection = true
    
    private lazy var sliderSize: CGSize = {
        let label = UILabel()
        label.text = " громкость "
        label.sizeToFit()
        return label.sizeThatFits(CGSize(width: .greatestFiniteMagnitude as CGFloat, height: .greatestFiniteMagnitude as CGFloat))
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupBackground()
        setupVerticalScale()
        setupHorizontalScale()
        setupVerticalSlider()
        setupHorizontalSlider()
        setupGestureRecognizer()
        setEnabled(false)
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        backgroundLayer.frame = bounds
    }
    
    private func setupBackground() {
        let l = CAGradientLayer()
        l.colors = [0, 1].map { UIColor(hex: "#5A50E2", alpha: $0) }.map(\.cgColor)
        l.locations = [0, 0.95]
        l.frame = bounds
        layer.addSublayer(l)
        
        self.backgroundLayer = l
    }
    
    private func setupVerticalScale() {
        let iv = UIImageView(image: UIImage(named: "verticalScale"))
        addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: topAnchor),
            iv.leadingAnchor.constraint(equalTo: leadingAnchor),
            iv.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(sliderSize.width / 2)),
            iv.widthAnchor.constraint(equalToConstant: sliderSize.height)
        ])
    }
    
    private func setupHorizontalScale() {
        let iv = UIImageView(image: UIImage(named: "horizontalScale"))
        addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sliderSize.width / 2),
            iv.bottomAnchor.constraint(equalTo: bottomAnchor),
            iv.trailingAnchor.constraint(equalTo: trailingAnchor),
            iv.heightAnchor.constraint(equalToConstant: sliderSize.height)
        ])
    }
    
    private func setupVerticalSlider() {
        let v = UIView()
        v.backgroundColor = .customFuchsia
        v.layer.cornerRadius = 4
        addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        verticalConstraint = v.topAnchor.constraint(equalTo: topAnchor, constant: sliderSize.width)
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalConstraint,
            v.heightAnchor.constraint(equalToConstant: sliderSize.width),
            v.widthAnchor.constraint(equalToConstant: sliderSize.height)
        ])
        
        let label = UILabel()
        label.text = " громкость "
        label.transform = CGAffineTransformMakeRotation(-90 * Double.pi / 180)
        v.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        
        self.verticalSlider = v
    }
    
    private func setupHorizontalSlider() {
        let v = UIView()
        v.backgroundColor = .customFuchsia
        v.layer.cornerRadius = 4
        addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        horizontalConstraint = v.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sliderSize.width)
        NSLayoutConstraint.activate([
            horizontalConstraint,
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
            v.heightAnchor.constraint(equalToConstant: sliderSize.height),
            v.widthAnchor.constraint(equalToConstant: sliderSize.width)
        ])
        
        let label = UILabel()
        label.text = " скорость "
        v.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        
        self.horizontalSlider = v
    }
    
    private func setupGestureRecognizer() {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(dragging))
        addGestureRecognizer(gr)
    }
    
    @objc func dragging(_ p: UIPanGestureRecognizer) {
        let delta = p.translation(in: self.superview!)
        switch p.state {
        case .began:
            decided = false
        case .changed:
            if !decided {
                decided = true
                isHorizontalDirection = abs(delta.x) >= abs(delta.y)
            }
            if isHorizontalDirection {
                horizontalConstraint.constant = min(max(horizontalConstraint.constant + delta.x, sliderSize.height), bounds.width - sliderSize.width)
                didChangeSpeed?(Float(horizontalConstraint.constant / (bounds.width - sliderSize.width - sliderSize.height)) * 4)
            } else {
                verticalConstraint.constant = min(max(verticalConstraint.constant + delta.y, 0.01), bounds.height - sliderSize.width - sliderSize.height)
                didChangeVolume?(Float(max(bounds.height - (verticalConstraint.constant + sliderSize.width + sliderSize.height), 0) / bounds.height))
            }
        default:
            break
        }
        
        p.setTranslation(.zero, in: self.superview!)
    }
    
    func setModel(volume: Float, speed: Float) {
        horizontalConstraint.constant = CGFloat(speed) / 4 * (bounds.width - sliderSize.width - sliderSize.height)
        verticalConstraint.constant = bounds.height - (bounds.height * CGFloat(volume)) - self.sliderSize.width - self.sliderSize.height
    }
    
    func setEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        verticalSlider.backgroundColor = enabled ? .customFuchsia : .lightGray
        horizontalSlider.backgroundColor = enabled ? .customFuchsia : .lightGray
    }
}
