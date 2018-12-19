//
//  LabelsUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol LabelsUIPopoverDelegate: class {
    func setLabels(added: [Int], removed: [Int])
    func moveTo(labelId: Int)
}

class LabelsUIPopover: BaseUIPopover {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var bigCancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var headerTitle = ""
    var labels = [Label]()
    var selectedLabels = [Int: Label]()
    var type : ActionType = .addLabels
    weak var delegate : LabelsUIPopoverDelegate?
    
    init(){
        super.init("LabelsUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "LabelTableViewCell", bundle: nil), forCellReuseIdentifier: "labeltablecell")
        titleLabel.text = headerTitle
        if(type == .moveTo){
            acceptButton.isHidden = true
            cancelButton.isHidden = true
        }else{
            bigCancelButton.isHidden = true
        }
    }
    
    @IBAction func onAcceptPress(_ sender: Any) {
        let removedLabels = labels.reduce([Int]()) { (rf, label) -> [Int] in
            guard selectedLabels[label.id] != nil else {
                return rf  + [label.id]
            }
            return rf
        }
        delegate?.setLabels(added: Array(selectedLabels.keys), removed: removedLabels)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    func preparePopover(rootView: UIViewController, height: Int){
        self.preferredContentSize = CGSize(width: Constants.popoverWidth, height: height)
        self.popoverPresentationController?.sourceView = rootView.view
        self.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: rootView.view.frame.size.width, height: rootView.view.frame.size.height)
        self.popoverPresentationController?.permittedArrowDirections = []
        self.popoverPresentationController?.backgroundColor = UIColor.white
    }
    
    class func instantiate(type: ActionType, selectedLabel: Int) -> LabelsUIPopover {
        let labelsPopover = LabelsUIPopover()
        labelsPopover.type = type
        labelsPopover.headerTitle = type == .moveTo ? String.localize("MOVE_TO") : String.localize("ADD_LABELS")
        let labels = type == .moveTo ? DBManager.getMoveableLabels(label: selectedLabel) : DBManager.getSettableLabels()
        labelsPopover.labels.append(contentsOf: labels)
        return labelsPopover
    }
}

extension LabelsUIPopover: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labeltablecell", for: indexPath) as! LabelTableViewCell
        let label = labels[indexPath.row]
        cell.setLabel(label.localized, color: UIColor(hex: label.color))
        cell.selectionStyle = .none
        if(type == .moveTo){
            cell.checkMarkView?.isHidden = true
            cell.dotView.isHidden = true
        } else {
            if(selectedLabels[label.id] == label){
                cell.setAsSelected()
            } else {
                cell.setAsDeselected()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = labels[indexPath.row]
        guard type == .addLabels else {
            delegate?.moveTo(labelId: label.id)
            dismiss(animated: false, completion: nil)
            return
        }
        if(selectedLabels[label.id] == label){
            selectedLabels[label.id] = nil
        }else{
            selectedLabels[label.id] = label
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

enum ActionType {
    case moveTo
    case addLabels
}
