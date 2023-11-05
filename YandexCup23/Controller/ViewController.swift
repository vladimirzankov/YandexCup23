//
//  ViewController.swift
//  YandexCup23
//
//  Created by Владимир Занков on 31.10.2023.
//

import UIKit
import AVFoundation
import Accelerate

final class ViewController: UIViewController {
    
    private var headerStackView: UIStackView!
    private var guitarView: UIView!
    private var drumsView: UIView!
    private var brassView: UIView!
    private var canvasView: CanvasView!
    private var footerStackView: UIStackView!
    private var buttonsPanelView: UIView!
    private var listButton: UIButton!
    private var playButton: UIButton!
    private var recordingButton: UIButton!
    private var micButton: UIButton!
    private var resetButton: UIButton!
    private var shareButton: UIButton!
    private var liveWaveformView: UIImageView!
    private var listView: UITableView!
    private var waveformMaskView: WaveformMaskView!
    private var fileWaveformView: UIView!
    private var progressView: UIView!
    
    private var progressConstraint: NSLayoutConstraint!
    
    private var selectedSounds: [Sound] = [] {
        didSet {
            listButton.isEnabled = !selectedSounds.isEmpty
            if selectedSounds.isEmpty {
                dismissListView()
            }
        }
    }
    
    private var currentSound: Sound? = nil {
        didSet {
            canvasView.setEnabled(currentSound != nil && currentSound?.category != .mic)
            if let currentSound {
                canvasView.setModel(volume: currentSound.volume, speed: currentSound.speed)
            }
        }
    }
    
    private var isPlaying = false {
        didSet {
            if isPlaying {
                selectedSounds
                    .filter { !$0.isMuted }
                    .forEach {
                        $0.player?.play()
                    }
            } else {
                selectedSounds.forEach {
                    $0.player?.pause()
                }
            }
        }
    }
    
    private var isListening = false
    private var isRecording = false
    private var isRecorded  = false
    
    private var engine = AVAudioEngine()
    
    private var monitor: MicMonitor! = nil
    
    private var replicatorTimer: Timer?
    private var replicatorTimerCounter = 0
    
    private var outfile: AVAudioFile?
    
    private var tapInstalled = false
    
    private let replicator = CAReplicatorLayer()
    private let dot = CALayer()
    private let dotLength: CGFloat = 2.0
    private let dotOffset: CGFloat = 4.0
    private var level: Float = 0.0
    private var lastTransformScale: CGFloat = 0.0
    
    private var progressAnimator: UIViewPropertyAnimator?
    
    private var outputPlayer: AVAudioPlayerNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupStackView()
        setupGuitarView()
        setupDrumsView()
        setupBrassView()
        setupCanvasView()
        setupFooterStackView()
        setupLiveWaveformView()
        setupFileWaveformView()
        setupWaveformProgressView()
        setupWaveformMaskView()
        setupButtonsPanelView()
        setupListButton()
        setupPlayButton()
        setupRecordingButton()
        setupMicButton()
        setupResetButton()
        setupShareButton()
        setupListView()
        setupNotificationHandlers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupReplicatorLayer()
        waveformMaskView.layer.frame = fileWaveformView.layer.bounds
    }
    
    private func setupStackView() {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.clipsToBounds = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        NSLayoutConstraint.activate([
            sv.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            sv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            sv.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])
        
        self.headerStackView = sv
    }
    
    private func setupGuitarView() {
        let iv = CategoryContainerView(category: .guitar)
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor, constant: 30)
        ])
        headerStackView.addArrangedSubview(iv)
        iv.didSelect = { [weak self] name in
            let sound = Sound(category: .guitar, name: name)
            self?.select(sound: sound)
        }
        
        self.guitarView = iv
    }
    
    private func setupDrumsView() {
        let iv = CategoryContainerView(category: .drums)
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor, constant: 30)
        ])
        headerStackView.addArrangedSubview(iv)
        
        iv.didSelect = { [weak self] name in
            let sound = Sound(category: .guitar, name: name)
            self?.select(sound: sound)
        }
        
        self.drumsView = iv
    }
    
    private func setupBrassView() {
        let iv = CategoryContainerView(category: .brass)
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor, constant: 30)
        ])
        headerStackView.addArrangedSubview(iv)
        iv.didSelect = { [weak self] name in
            let sound = Sound(category: .guitar, name: name)
            self?.select(sound: sound)
        }
        
        self.brassView = iv
    }
    
    private func setupCanvasView() {
        let v = CanvasView()
        view.insertSubview(v, belowSubview: headerStackView)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            v.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 30),
            v.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])
        
        v.didChangeVolume = { [weak self] volume in
            guard let self else { return }
            currentSound?.volume = volume
            currentSound?.player?.volume = volume
        }
        
        v.didChangeSpeed = { [weak self] speed in
            print(speed)
            guard let self, let currentSound else { return }
            currentSound.speed = speed
            currentSound.player?.stop()
            
            let url = currentSound.fileURL
            let f = try! AVAudioFile(forReading: url)
            
            let buffer = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(Float(f.length) / speed))
            try! f.read(into:buffer!)
            let time = AVAudioTime(sampleTime: AVAudioFramePosition(Float(44100 / 10)), atRate: 44100)
            currentSound.player?.scheduleBuffer(buffer!, at: time, options: .loops)
            if isPlaying {
                currentSound.player?.play()
            }
        }
        
        self.canvasView = v
    }
    
    private func setupFooterStackView() {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        NSLayoutConstraint.activate([
            sv.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            sv.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 13),
            sv.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            sv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            sv.heightAnchor.constraint(equalTo: headerStackView.heightAnchor),
        ])
        
        self.footerStackView = sv
    }
    
    private func setupLiveWaveformView() {
        let v = UIImageView()
        footerStackView.addArrangedSubview(v)
        self.liveWaveformView = v
    }
    
    private func setupReplicatorLayer() {
        replicator.frame = liveWaveformView.bounds
        liveWaveformView.layer.addSublayer(replicator)
        
        dot.frame = CGRect(
            x: replicator.frame.size.width - dotLength,
            y: replicator.position.y,
            width: dotLength,
            height: dotLength)
        
        dot.backgroundColor = UIColor.gray.cgColor
        
        replicator.addSublayer(dot)
        replicator.instanceCount = Int(liveWaveformView.frame.size.width / dotOffset)
        replicator.instanceTransform = CATransform3DMakeTranslation(-dotOffset, 0.0, 0.0)
        replicator.instanceDelay = 0.02
        
        replicatorTimer = Timer.scheduledTimer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(updateReplicatorLayer),
            userInfo: nil,
            repeats: true)
    }
    
    @objc func updateReplicatorLayer(timer: Timer) {
        self.replicatorTimerCounter = (replicatorTimerCounter + 1) % replicator.instanceCount
        guard currentSound?.player != nil, !isListening else { return }
        
        let scaleFactor = max(2, CGFloat(self.level) + 50) / 2
        let scale = CABasicAnimation(keyPath: "transform.scale.y")
        scale.fromValue = self.lastTransformScale
        scale.toValue = scaleFactor
        scale.duration = 0.1
        scale.isRemovedOnCompletion = false
        scale.fillMode = .forwards
        self.dot.add(scale, forKey: String(replicatorTimerCounter))
        
        self.lastTransformScale = scaleFactor
    }
    
    private func setupFileWaveformView() {
        let v = UIView()
        v.backgroundColor = .white
        
        footerStackView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: liveWaveformView.topAnchor),
            v.leadingAnchor.constraint(equalTo: liveWaveformView.leadingAnchor),
            v.bottomAnchor.constraint(equalTo: liveWaveformView.bottomAnchor),
            v.trailingAnchor.constraint(equalTo: liveWaveformView.trailingAnchor)
        ])
        
        self.fileWaveformView = v
    }
    
    private func setupWaveformProgressView() {
        let v = UIView()
        v.backgroundColor = .customFuchsia
        fileWaveformView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        self.progressConstraint = v.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: liveWaveformView.topAnchor),
            v.leadingAnchor.constraint(equalTo: liveWaveformView.leadingAnchor),
            v.bottomAnchor.constraint(equalTo: liveWaveformView.bottomAnchor),
            progressConstraint
        ])
        self.progressView = v
    }
    
    private func setupWaveformMaskView() {
        let mask = WaveformMaskView(color: .green)
        self.waveformMaskView = mask
        self.fileWaveformView.layer.mask = mask.layer
    }
    
    private func setupButtonsPanelView() {
        let v = UIView()
        footerStackView.addArrangedSubview(v)
        self.buttonsPanelView = v
    }
    
    private func setupListButton() {
        var config = UIButton.Configuration.custom()
        config.title = "Слои"
        config.titleAlignment = .leading
        config.image = UIImage(named: "arrow")?.withRenderingMode(.alwaysTemplate)
        config.imagePlacement = .trailing
        config.imagePadding = 15
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in
            self.listButton.isSelected.toggle()
            self.listButton.imageView?.transform = self.listButton.isSelected ? CGAffineTransformMakeRotation(180 * Double.pi / 180) : CGAffineTransform.identity
            self.isPlaying = false
            self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            if self.listButton.isSelected {
                self.showListView()
            } else {
                self.dismissListView()
            }
        })
        button.tintColor = .customGray
        button.isEnabled = false
        button.configurationUpdateHandler = { button in
            switch button.state {
            case [.selected, .highlighted]:
                button.configuration?.background.backgroundColor = .customFuchsia
            case .selected:
                button.configuration?.background.backgroundColor = .customFuchsia
            case .highlighted:
                button.configuration?.background.backgroundColor = .white
            case .disabled:
                button.configuration?.background.backgroundColor = .white
            default:
                button.configuration?.background.backgroundColor = .white
            }
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: buttonsPanelView.topAnchor),
            button.leadingAnchor.constraint(equalTo: buttonsPanelView.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2, constant: 8)
        ])
        
        self.listButton = button
    }
    
    private func setupPlayButton() {
        var config = UIButton.Configuration.custom()
        config.image = UIImage(systemName: "play.fill")?.withRenderingMode(.alwaysTemplate)
        config.imagePadding = 8
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            self.listView.isHidden = true
            
            if self.isRecorded {
                self.playOutput()
            } else {
                self.isPlaying.toggle()
            }
            playButton.setImage(UIImage(systemName: isPlaying || isRecorded ? "pause.fill" : "play.fill"), for: .normal)
        })
        button.tintColor = .customGray
        button.translatesAutoresizingMaskIntoConstraints = false
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: buttonsPanelView.topAnchor),
            button.trailingAnchor.constraint(equalTo: buttonsPanelView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        
        self.playButton = button
    }
    
    private func setupRecordingButton() {
        var config = UIButton.Configuration.custom()
        config.image = UIImage(systemName: "circlebadge.fill")?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            self.listView.isHidden = true
            
            if !self.isRecording {
                self.startRecording()
            } else {
                self.stopRecording()
            }
        })
        button.tintColor = .customGray
        button.translatesAutoresizingMaskIntoConstraints = false
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: buttonsPanelView.topAnchor),
            button.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -8),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        
        self.recordingButton = button
    }
    
    private func setupMicButton() {
        var config = UIButton.Configuration.custom()
        config.image = UIImage(systemName: "mic.fill")?.withRenderingMode(.alwaysTemplate)
        config.imagePadding = 10
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.listView.isHidden = true
            self?.checkForRecordAccess(onSuccess: {
                guard let self else { return }
                if !self.isListening {
                    self.startListening()
                } else {
                    self.stopListening()
                }
            }, onFailure: { [weak self] in
                self?.micButton.isEnabled = false
            })
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .customGray
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: buttonsPanelView.topAnchor),
            button.trailingAnchor.constraint(equalTo: recordingButton.leadingAnchor, constant: -8),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        
        self.micButton = button
    }
    
    private func setupResetButton() {
        var config = UIButton.Configuration.custom()
        config.image = UIImage(systemName: "trash.fill")?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            resetButton.isHidden = true
            shareButton.isHidden = true
            selectedSounds = []
            currentSound = nil
            isRecorded = false
            liveWaveformView.alpha = 1
            setupWaveformMaskView()
            
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .customGray
        button.isHidden = true
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: micButton.topAnchor),
            button.leadingAnchor.constraint(equalTo: micButton.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: micButton.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: micButton.trailingAnchor)
        ])
        
        self.resetButton = button
    }
    
    private func setupShareButton() {
        var config = UIButton.Configuration.custom()
        config.image = UIImage(systemName: "square.and.arrow.up.fill")?.withRenderingMode(.alwaysTemplate)
        config.imagePadding = 10
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.share()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .customGray
        button.isHidden = true
        buttonsPanelView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: recordingButton.topAnchor),
            button.leadingAnchor.constraint(equalTo: recordingButton.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: recordingButton.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: recordingButton.trailingAnchor)
        ])
        
        self.shareButton = button
    }
    
    private func setupListView() {
        let v = UITableView()
        v.backgroundColor = .clear
        v.separatorStyle = .none
        v.delegate = self
        v.dataSource = self
        v.register(ListViewCell.self, forCellReuseIdentifier: "Cell")
        v.isHidden = true
        view.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: canvasView.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            v.bottomAnchor.constraint(equalTo: buttonsPanelView.topAnchor),
            v.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])
        
        self.listView = v
    }
    
    private func setupNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func select(sound: Sound) {
        self.currentSound = sound
        self.canvasView.setModel(volume: sound.volume, speed: sound.speed)
        if self.selectedSounds.firstIndex(where: { $0 === sound }) == nil {
            
            self.selectedSounds.append(sound)
            self.play(sound)
        }
        self.listView.reloadData()
    }
    
    private func showListView() {
        listView.isHidden = false
        disableButtons(micButton, recordingButton, playButton)
    }
    
    private func dismissListView() {
        listView.isHidden = true
        enableButtons()
    }
    
    private func startListening() {
        disableButtons(listButton, recordingButton, playButton)
        self.isListening = true
        isPlaying = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        monitor = MicMonitor()
        monitor.startMonitoringWithHandler { level in
            let scaleFactor = max(2, CGFloat(level) + 50) / 2
            let scale = CABasicAnimation(keyPath: "transform.scale.y")
            scale.fromValue = self.lastTransformScale
            scale.toValue = scaleFactor
            scale.duration = 0.1
            scale.isRemovedOnCompletion = false
            scale.fillMode = .forwards
            self.dot.add(scale, forKey: nil)
            
            self.lastTransformScale = scaleFactor
        }
    }
    
    private func stopListening() {
        self.isListening = false
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        enableButtons()
        micButton.tintColor = .customGray
        monitor.stopMonitoring()
        
        let sound = Sound(category: .mic, name: "Микрофон")
        self.currentSound = sound
        self.canvasView.setModel(volume: sound.volume, speed: sound.speed)
        self.selectedSounds.append(sound)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.play(sound)
        }
        
        self.listView.reloadData()
    }
    
    func startRecording() {
        disableButtons(listButton, micButton, playButton)
        self.isPlaying = true
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        self.isRecording = true
        self.recordingButton.tintColor = .customRed
        
        let fm = FileManager.default
        let doc = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let outurl = doc.appendingPathComponent("output.aif", isDirectory:false)
        try? fm.removeItem(at: outurl)
        self.outfile = try? AVAudioFile(forWriting: outurl, settings: self.engine.mainMixerNode.outputFormat(forBus: 0).settings)
        canvasView.setEnabled(false)
    }
    
    private func stopRecording() {
        isRecording = false
        isRecorded = true
        isPlaying = false
        liveWaveformView.alpha = 0
        recordingButton.tintColor = .customGray
        resetButton.isHidden = false
        shareButton.isHidden = false
        outfile = nil
        
        enableButtons()
        playOutput()
        return
    }
    
    func play(_ sound: Sound) {
        let url = sound.fileURL
        let f = try! AVAudioFile(forReading: url)
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let mixer = engine.mainMixerNode
        engine.connect(player, to: mixer, format: f.processingFormat)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length))
        try! f.read(into:buffer!)
        player.scheduleBuffer(buffer!, at: nil, options: .loops)
        
        let format = f.processingFormat
        
        if !tapInstalled {
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
                guard let self else { return }
                let channelData = buffer.floatChannelData?[0]
                if let channelData = channelData {
                    
                    let frameCount = Int(buffer.frameLength)
                    var totalPower: Float = 0.0
                    
                    for i in 0..<frameCount {
                        let sample = channelData[i]
                        totalPower += sample * sample
                    }
                    
                    let averagePower = totalPower / Float(frameCount)
                    self.level = 10.0 * log10(averagePower)
                    guard self.currentSound?.player != nil else { return }
                    
                    if self.outfile != nil {
                        try? self.outfile?.write(from: buffer)
                    }
                }
                
            }
            tapInstalled = true
        }
        
        self.engine.prepare()
        try? self.engine.start()
        
        sound.player = player
        if isPlaying {
            player.play()
        }
    }
    
    private func playOutput() {
        self.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        let fm = FileManager.default
        let doc = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let outurl = doc.appendingPathComponent("output.aif", isDirectory:false)
        let f = try! AVAudioFile(forReading: outurl)
        
        self.waveformMaskView.audioURL = outurl
        
        let player = AVAudioPlayerNode()
        self.engine.attach(player)
        
        self.waveformMaskView.onCalculateDuration = { [weak self] duration in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.progressAnimator == nil else {
                    self.outputPlayer?.pause()
                    self.outputPlayer?.stop()
                    self.outputPlayer?.reset()
                    self.progressAnimator?.stopAnimation(false)
                    self.progressAnimator?.finishAnimation(at: .start)
                    self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    return
                }
                self.progressConstraint.constant = 0
                self.view.layoutIfNeeded()
                let anim = UIViewPropertyAnimator(duration: duration, curve: .linear)
                self.progressConstraint.constant = self.waveformMaskView.frame.size.width
                anim.addAnimations {
                    self.view.layoutIfNeeded()
                }
                anim.addCompletion { [weak self] _ in
                    self?.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    self?.progressAnimator = nil
                }
                anim.startAnimation()
                self.progressAnimator = anim
                
                let mixer = self.engine.mainMixerNode
                self.engine.connect(player, to: mixer, format: f.processingFormat)
                player.scheduleFile(f, at: nil)
                player.play()
                self.outputPlayer = player
            }
        }
        
        
    }
    
    private func share() {
        let fm = FileManager.default
        let doc = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let outurl = doc.appendingPathComponent("output.aif", isDirectory:false)
        let activityViewController = UIActivityViewController(activityItems: [outurl], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func enableButtons() {
        listButton.isEnabled = selectedSounds.count > 0
        micButton.isEnabled = AVAudioSession.sharedInstance().recordPermission != .denied
        recordingButton.isEnabled = true
        playButton.isEnabled = true
    }
    
    private func disableButtons(_ buttons: UIButton...) {
        buttons.forEach { $0.isEnabled = false }
    }
    
    @objc func willEnterForeground() {
        micButton.isEnabled = AVAudioSession.sharedInstance().recordPermission != .denied
    }
    
    private func checkForRecordAccess(onSuccess: (() -> Void)?, onFailure: (() -> Void)?) {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted: onSuccess?()
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        DispatchQueue.main.async {
                            onSuccess?()
                        }
                    } else {
                        onFailure?()
                    }
                }
            }
        case .denied:
            onFailure?()
        @unknown default: fatalError()
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return selectedSounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? ListViewCell else { return UITableViewCell() }
        let sound = selectedSounds[indexPath.row]
        cell.configure(with: sound, isCurrent: sound === currentSound)
        cell.didSelect = { [weak self] in
            self?.currentSound = sound
            tableView.reloadData()
        }
        cell.didTapPlayPause = {
            sound.isPlaying.toggle()
            if sound.isPlaying {
                sound.player?.play()
            } else {
                sound.player?.pause()
            }
            
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        cell.didTapMuteUnmute = {
            sound.isMuted.toggle()
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        cell.didTapDelete = { [weak self] in
            guard let self,
                  let index = self.selectedSounds.firstIndex(where: { $0 === sound })
            else { return }
            sound.player?.stop()
            selectedSounds.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .top)
            if sound === currentSound {
                currentSound = selectedSounds.last
            }
            tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: .zero)
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTapHeader))
        headerView.addGestureRecognizer(gr)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let diff = tableView.contentSize.height - tableView.bounds.height
        return diff > 0 ? 0 : -diff
    }
    
    @objc func didTapHeader() {
        listView.isHidden = true
    }
}

extension UIButton.Configuration {
    
    static func custom() -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .white
        config.background.cornerRadius = 4
        return config
    }
}
