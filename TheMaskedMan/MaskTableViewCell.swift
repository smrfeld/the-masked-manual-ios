//
/*
File: ModelTableViewCell.swift
Created by: Oliver K. Ernst
Date: 11/22/20

MIT License

Copyright (c) 2020 Oliver K. Ernst

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/ 

import UIKit

class MaskTableViewCell: UITableViewCell, ShowMaskDetailsProtocol {

    private let fda = " FDA-approved"
    private let niosh = " NIOSH-approved"
    private let emergency = " Emergency-authorized"
    private let recalled = " Recalled"
    private let revoked = " Revoked"

    @IBOutlet weak var model_label: UILabel!
    @IBOutlet weak var company_label: UILabel!
    @IBOutlet weak var fda_label: UILabel!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var niosh_label: UILabel!
    @IBOutlet weak var extra_label: UILabel!
    
    func reload(mask: Mask) {
        self.model_label.text = mask.model
        self.company_label.text = mask.company
        
        mask.show_mask_details(delegate: self)
    }
    
    func set_extra(_ val: MaskExtra) {
        switch val {
        case .emergency_authorized:
            extra_label.attributedText = get_str_without_strikethrough(emergency)
            extra_label.textColor = UIColor.okGreen
            extra_label.isHidden = false
        case .recalled:
            extra_label.attributedText = get_str_without_strikethrough(recalled)
            extra_label.textColor = UIColor.notOkRed
            extra_label.isHidden = false
        case .revoked:
            extra_label.attributedText = get_str_without_strikethrough(revoked)
            extra_label.textColor = UIColor.notOkRed
            extra_label.isHidden = false
        case .none:
            extra_label.isHidden = true
        }
    }
    
    func set_niosh(_ val: MaskNIOSH) {
        switch val {
        case .approved:
            niosh_label.attributedText = get_str_without_strikethrough(niosh)
            niosh_label.textColor = UIColor.okGreen
        case .not_approved:
            niosh_label.attributedText = get_str_with_strikethrough(niosh)
            niosh_label.textColor = UIColor.notOkRed
        case .not_applicable:
            niosh_label.attributedText = get_str_with_strikethrough(niosh)
            niosh_label.textColor = UIColor.mehGray
        }
    }
    
    func set_fda(_ val: MaskFDA) {
        switch val {
        case .approved:
            fda_label.attributedText = get_str_without_strikethrough(fda)
            fda_label.textColor = UIColor.okGreen
        case .not_approved:
            fda_label.attributedText = get_str_with_strikethrough(fda)
            fda_label.textColor = UIColor.notOkRed
        }
    }
    
    func set_image(_ image: UIImage) {
        image_view.image = image
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
