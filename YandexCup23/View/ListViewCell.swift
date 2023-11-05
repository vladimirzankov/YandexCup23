//
//  ListViewCell.swift
//  YandexCup23
//
//  Created by Владимир Занков on 01.11.2023.
//

import UIKit

final class ListViewCell: UITableViewCell {
    
    var didSelect: (() -> Void)?
    var didTapPlayPause: (() -> Void)?
    var didTapMuteUnmute: (() -> Void)?
    var didTapDelete: (() -> Void)?
    
    private var containerView: UIView!
    private var titleLabel: UILabel!
    private var playButton: UIButton!
    private var muteButton: UIButton!
    private var deleteButton: UIButton!
    private var closeButton: UIButton!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none
        
        setupContainer()
        setupTitleLabel()
        setupPlayButton()
        setupMuteButton()
        setupDeleteButton()
        setupGestureRecognizer()
    }
    
    private func setupContainer() {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 4
        contentView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        self.containerView = v
    }
    
    private func setupTitleLabel() {
        let label = UILabel()
        label.text = "Ударные 1"
        label.textAlignment = .left
        label.textColor = .black
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10)
        ])
        
        self.titleLabel = label
    }
    
    private func setupPlayButton() {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .clear
        config.image = UIImage(named: "play")
        config.imagePadding = 10
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapPlayPause?()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.widthAnchor.constraint(equalTo: heightAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.playButton = button
    }
    
    private func setupMuteButton() {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .clear
        config.image = UIImage(named: "soundOff")
        config.imagePadding = 10
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapMuteUnmute?()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.widthAnchor.constraint(equalTo: heightAnchor),
            button.leadingAnchor.constraint(equalTo: playButton.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        self.muteButton = button
    }
    
    private func setupDeleteButton() {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = UIColor(hex: "#E4E4E4")
        config.background.cornerRadius = 4
        config.image = UIImage(named: "close")
        config.imagePadding = 10
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapDelete?()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor),
            button.widthAnchor.constraint(equalTo: heightAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        self.deleteButton = button
    }
    
    func configure(with sound: Sound, isCurrent: Bool) {
        titleLabel.text = sound.name
        playButton.setImage(UIImage(named: sound.isPlaying ? "pause": "play"), for: .normal)
        muteButton.setImage(UIImage(named: sound.isMuted ? "soundOff" : "soundOn"), for: .normal)
        containerView.backgroundColor = isCurrent ? .customFuchsia : .white

    }
    
    private func setupGestureRecognizer() {
        let gr = UITapGestureRecognizer(target: self, action: #selector(tap))
        contentView.addGestureRecognizer(gr)
    }
    
    @objc func tap() {
        didSelect?()
    }
}
