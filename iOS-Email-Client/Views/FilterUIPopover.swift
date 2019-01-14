//
//  FilterUIPopover.swift
//  iOS-Email-Client
//
//  Created by Saul Mestanza on 1/14/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol FilterUIPopoverDelegate: class{
    func didAcceptPressed(label: String)
}

class FilterUIPopover : BaseUIPopover {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var showAllButton: DLRadioButton!
    @IBOutlet weak var showUnreadButton: DLRadioButton!
    @IBOutlet weak var viewPopover: UIView!
    weak var delegate : FilterUIPopoverDelegate?
    var labels = [String.localize("SHOW_ALL"), String.localize("SHOW_UNREAD")]
    var selectedLabel = String()
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    init(){
        super.init("FilterUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func onShowCancelPressed(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onShowAcceptPressed(_ sender: Any) {
        delegate?.didAcceptPressed(label: selectedLabel)
        dismiss(animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(selectedLabel == String.localize("SHOW_ALL")){
            showAllButton.isSelected = true
        }else{
            showUnreadButton.isSelected = true
        }
        applyTheme()
    }
    
    @objc func logSelectedButton(radioButton : DLRadioButton) {
        selectedLabel = radioButton.selected()!.titleLabel!.text!
    }
    
    func applyTheme() {
        showAllButton.setTitle(String.localize("SHOW_ALL"), for: []);
        showAllButton.setTitleColor(theme.mainText, for: []);
        showAllButton.iconColor = theme.mainText;
        showAllButton.indicatorColor = theme.mainText;
        showAllButton.isIconOnRight = true
        showAllButton.addTarget(self, action: #selector(logSelectedButton), for: UIControl.Event.touchUpInside);
        
        showUnreadButton.setTitle(String.localize("SHOW_UNREAD"), for: []);
        showUnreadButton.setTitleColor(theme.mainText, for: []);
        showUnreadButton.iconColor = theme.mainText;
        showUnreadButton.indicatorColor = theme.mainText;
        showUnreadButton.isIconOnRight = true
        showUnreadButton.addTarget(self, action: #selector(logSelectedButton), for: UIControl.Event.touchUpInside);
        
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        viewPopover.backgroundColor = theme.background
        cancelButton.backgroundColor = theme.popoverButton
        cancelButton.setTitleColor(theme.mainText, for: .normal)
        acceptButton.backgroundColor = theme.popoverButton
        acceptButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    func preparePopover(rootView: UIViewController, height: Int){
        self.preferredContentSize = CGSize(width: Constants.popoverWidth, height: height)
        self.popoverPresentationController?.sourceView = rootView.view
        self.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: rootView.view.frame.size.width, height: rootView.view.frame.size.height)
        self.popoverPresentationController?.permittedArrowDirections = []
        self.popoverPresentationController?.backgroundColor = theme.overallBackground
    }
    
    class func instantiate(initLabel: String) -> FilterUIPopover {
        let filterPopover = FilterUIPopover()
        filterPopover.selectedLabel = initLabel
        return filterPopover
    }
}
