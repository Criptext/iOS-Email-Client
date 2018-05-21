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
    }
    
}

extension HistoryUIPopover: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}
