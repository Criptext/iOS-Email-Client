//
//  MoveViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/11/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class MoveMailViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var selectedLabel:MyLabel!
    var selectedMailbox:MyLabel?
    var labels = [MyLabel.inbox, MyLabel.sent, MyLabel.junk, MyLabel.trash]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell){
            self.selectedMailbox = labels[indexPath.row]
        }
    }
}

extension MoveMailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MoveMailTableViewCell", for: indexPath) as! MoveMailTableViewCell
        
        let label = labels[indexPath.row]
        
        cell.mailLabel.text = label.description
        cell.mailImageView.image = label.image
        
        if self.selectedLabel == label {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.mailImageView.tintColor = Icon.disabled.color
            cell.mailLabel.textColor = Icon.disabled.color
            cell.isUserInteractionEnabled = false
        }else{
            cell.selectionStyle = UITableViewCellSelectionStyle.blue
            cell.mailImageView.tintColor = Icon.activated.color
            cell.mailLabel.textColor = UIColor.black
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
}

extension MoveMailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 67.5
    }
}
