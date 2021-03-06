//
//  QuantityControlCell.swift
//  TaskTrackr
//
//  Created by Eric Ho on 29/10/18.
//  Copyright © 2018 LomoStudio. All rights reserved.
//

import UIKit

class NumberControlCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberField: UITextField!
    @IBOutlet weak var numberControl: UIStepper!
    
    static let ID = "NumberControlCell"
    // store indexPath which this cell is used for
    var indexPath: IndexPath?
    var numberInCellChanged: ((IndexPath, Int)->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        numberControl.addTarget(self, action: #selector(onNumberChanged(_:)), for: .valueChanged)

    }
    
    @objc func onNumberChanged(_ sender: UIStepper) {
        let number = Int(sender.value)
        numberField.text = number.description
        // "Notify" client view controller
        if let indexPath = self.indexPath {
            self.numberInCellChanged?(indexPath, number)
        }
    }
    
    override func prepareForReuse() {
        nameLabel.text = ""
        numberControl.value = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }
    
}
