//
//  OptionsPickerUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class OptionsPickerUIPopover: BaseUIPopover {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var onComplete: ((String?) -> Void)?
    var options: [String]!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    
    init(){
        super.init("OptionsPickerUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        pickerView.dataSource = self
        pickerView.delegate = self
        applyTheme()
    }
    
    func applyTheme() {
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        okButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        cancelButton.setTitleColor(theme.mainText, for: .normal)
        okButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        let option = options[pickerView.selectedRow(inComponent: 0)]
        self.dismiss(animated: true) { [weak self] in
            self?.onComplete?(option)
        }
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true) { [weak self] in
            self?.onComplete?(nil)
        }
    }
}

extension OptionsPickerUIPopover: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String.localize(options[row])
    }
    
    func pickerView(_: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = String.localize(options[row])
        return NSAttributedString(string: titleData, attributes: [NSAttributedStringKey.foregroundColor:theme.mainText])
    }
}
