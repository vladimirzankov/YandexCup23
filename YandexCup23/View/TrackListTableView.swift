//
//  TrackListTableView.swift
//  YandexCup23
//
//  Created by Владимир Занков on 01.11.2023.
//

import UIKit

final class TrackListTableView: UITableView {
    
    var didPlay: ((Sound) -> Void)?
    var didPause: ((Sound) -> Void)?
    var didMute: ((Sound) -> Void)?
    var didUnmute: ((Sound) -> Void)?
    var didDelete: ((Sound) -> Void)?
    
    var sounds: [Sound] = [] {
        didSet {
            reloadData()
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero, style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        separatorStyle = .none
        delegate = self
        dataSource = self
        register(ListViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension TrackListTableView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? ListViewCell else { return UITableViewCell() }
        cell.configure(with: sounds[indexPath.row], isCurrent: true)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
          return 48
      }

      func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
          let headerView = UIView(frame: .zero)
          headerView.isUserInteractionEnabled = false
          return headerView
      }

      func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
          let diff = tableView.contentSize.height - tableView.bounds.height
          return diff > 0 ? 0 : -diff
      }
}
