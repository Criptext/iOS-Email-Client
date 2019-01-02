//
//  AttachmentHistoryUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class HistoryUIPopover: BaseUIPopover{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var historyTitleLabel: UILabel!
    @IBOutlet weak var historyTitleImage: UIImageView!
    @IBOutlet weak var emptyMessageLabel: UILabel!
    var historyCellName: String!
    var historyTitleText: String!
    var emptyMessage: String!
    var historyImage: UIImage!
    var cellHeight: CGFloat = 0
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    init(){
        super.init("HistoryUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: historyCellName, bundle: nil), forCellReuseIdentifier: "historyCell")
        historyTitleLabel.text = historyTitleText
        historyTitleImage.image = historyImage
        emptyMessageLabel.text = emptyMessage
        tableView.isHidden = true
        applyTheme()
    }
    
    func applyTheme() {
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        historyTitleLabel.textColor = theme.mainText
        emptyMessageLabel.textColor = theme.mainText
        tableView.backgroundColor = theme.background
    }
}

extension HistoryUIPopover: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        cell.backgroundColor = theme.background
        cell.textLabel?.textColor = theme.mainText
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}
