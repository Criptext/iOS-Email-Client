//
//  SettingsLabelsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsLabelsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var generalOptionsContainerView: MoreOptionsUIView!
    var labels = [Label]()
    var myAccount: Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    var labelOptionsInterface: LabelOptionsInterface?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String.localize("LABELS")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        labels.append(DBManager.getLabel(SystemLabel.starred.id)!)
        labels.append(contentsOf: DBManager.getUserLabels(account: myAccount, visible: false))
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib(nibName: "LabelsFooterTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsAddLabel")
        self.tableView.register(UINib(nibName: "LabelsHeaderTableViewCell", bundle: nil ), forHeaderFooterViewReuseIdentifier: "settingsHeaderLabel")
        self.applyTheme()
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RequestManager.shared.delegates.append(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RequestManager.shared.delegates.removeLast()
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("LABELS"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("LABELS"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
    }
    
    func presentPopover(){
        let theme: Theme = ThemeManager.shared.theme
        let parentView = (tabsController?.view ?? self.view)!
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = String.localize("ADD_LABEL")
        changeNamePopover.onOk = { [weak self] text in
            self?.createLabel(text: text)
        }
        changeNamePopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: Constants.singleTextPopoverHeight)
        changeNamePopover.popoverPresentationController?.sourceView = parentView
        changeNamePopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: parentView.frame.size.width, height: parentView.frame.size.height)
        changeNamePopover.popoverPresentationController?.permittedArrowDirections = []
        changeNamePopover.popoverPresentationController?.backgroundColor = theme.overallBackground
        self.present(changeNamePopover, animated: true)
    }
    
    func createLabel(text: String){
        let labelText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existingLabel = DBManager.getLabel(text: labelText) {
            self.showAlert(String.localize("REPEATED_LABEL"), message: String.localize("LABEL_EXISTS", arguments: existingLabel.text), style: .alert)
            return
        }
        let label = Label(labelText)
        label.account = myAccount
        DBManager.store(label, incrementId: true)
        self.labels.append(label)
        self.tableView.insertRows(at: [IndexPath(row: self.labels.count - 1, section: 0)], with: .automatic)
        let params = EventData.Peer.NewLabel(text: label.text, color: label.color, uuid: label.uuid)
        DBManager.createQueueItem(params: ["cmd": Event.Peer.newLabel.rawValue, "params": params.asDictionary()], account: myAccount)
    }
    
    func createEditLabelPopover(label: Label, row: Int){
        let popover = GenericSingleInputPopover()
        popover.initialTitle = String.localize("EDIT_LABEL_DIALOG_TITLE")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("CHANGE")
        popover.startingText = label.text
        popover.attributedPlaceholder = NSAttributedString(string: String.localize("CHANGE_NAME"), attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder])
        popover.onOkPress = { [weak self] text in
            guard let weakSelf = self else {
                return
            }
            guard let account = weakSelf.myAccount else {
                return
            }
            DBManager.updateLabelName(label, newName: text)
            let params = EventData.Peer.EditLabel(text: label.text, color: label.color, uuid: label.uuid)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.editLabel.rawValue, "params": params.asDictionary()], account: account)
            weakSelf.tableView.reloadData()
        }
        self.presentPopover(popover: popover, height: 200)
    }
    
    func createDeleteLabelPopover(label: Label, row: Int){
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("DELETE_LABEL_DIALOG_TITLE")
        popover.initialMessage = String.localize("DELETE_LABEL_DIALOG_MESSAGE", arguments: label.text)
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("YES")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            if(accept){
                guard let account = weakSelf.myAccount else {
                    return
                }
                let params = EventData.Peer.DeleteLabel(uuid: label.uuid)
                DBManager.createQueueItem(params: ["cmd": Event.Peer.deleteLabel.rawValue, "params": params.asDictionary()], account: account)
                DBManager.deleteLabel(label: label)
                weakSelf.labels.remove(at: row)
                weakSelf.tableView.reloadData()
            }
        }
        self.presentPopover(popover: popover, height: 200)
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsLabelsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let label = labels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsLabelCell") as! LabelsLabelTableViewCell
        cell.fillFields(label: label)
        cell.clickMore = { [weak self] in
            guard let weakSelf = self else {
                    return
            }
            weakSelf.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            weakSelf.labelOptionsInterface = LabelOptionsInterface(label: label)
            weakSelf.labelOptionsInterface?.delegate = weakSelf
            weakSelf.generalOptionsContainerView.setDelegate(newDelegate: weakSelf.labelOptionsInterface!)
            weakSelf.toggleGeneralOptionsView()
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsAddLabel") as! LabelsFooterViewCell
        cell.onTapCell = { [weak self] in
            self?.presentPopover()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "settingsHeaderLabel")
    }
    
    @objc func toggleGeneralOptionsView(){
        guard generalOptionsContainerView.isHidden else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.showMoreOptions()
    }
    
    func didReceiveEvents(result: EventData.Result) {
        if(result.updateSideMenu){
            labels.removeAll()
            labels.append(DBManager.getLabel(SystemLabel.starred.id)!)
            labels.append(contentsOf: DBManager.getUserLabels(account: myAccount, visible: false))
            self.reloadView()
        }
    }
}

extension SettingsLabelsViewController: LabelTableViewCellDelegate {
    func tableViewCellDidTapCheck(_ cell: LabelsLabelTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let label = labels[indexPath.row]
        DBManager.updateLabel(label, visible: !label.visible)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension SettingsLabelsViewController: RequestDelegate {
    func finishRequest(accountId: String, result: EventData.Result) {
        self.didReceiveEvents(result: result)
    }
    
    func errorRequest(accountId: String, response: ResponseData) {
        guard !myAccount.isInvalidated && myAccount.compoundKey == accountId else {
            return
        }
    }
}

extension SettingsLabelsViewController {
    func reloadView() {
        self.applyTheme()
        tableView.reloadData()
    }
}

extension SettingsLabelsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SettingsLabelsViewController: LabelOptionsInterfaceDelegate {
    func onEditPress() {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        self.toggleGeneralOptionsView()
        let label = labels[indexPath.row]
        self.createEditLabelPopover(label: label, row: indexPath.row)
    }
    
    func onDeletePress() {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        self.toggleGeneralOptionsView()
        let label = labels[indexPath.row]
        self.createDeleteLabelPopover(label: label, row: indexPath.row)
    }
    
    func onClose() {
        self.toggleGeneralOptionsView()
    }
}
