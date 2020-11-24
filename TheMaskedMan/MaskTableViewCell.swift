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

    private let fda_approved = "FDA"
    private let fda_not_approved = "FDA"
    private let niosh_approved = "NIOSH"
    private let niosh_not_approved = "NIOSH"
    private let niosh_not_applicable = "NIOSH"
    private let emergency = "Emergency"
    private let recalled = "Recalled"
    private let revoked = "Revoked"

    /*
    private let fda_approved = "FDA-approved  "
    private let fda_not_approved = "Not FDA-approved  "
    private let niosh_approved = "NIOSH-approved  "
    private let niosh_not_approved = "Not NIOSH-approved  "
    private let niosh_not_applicable = "NIOSH not applicable  "
    private let emergency = "Emergency-authorized  "
    private let recalled = "Recalled  "
    private let revoked = "Revoked  "
     */

    @IBOutlet weak var model_label: UILabel!
    @IBOutlet weak var company_label: UILabel!
    @IBOutlet weak var fda_label: UILabel!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var niosh_label: UILabel!
    @IBOutlet weak var extra_label: UILabel!
    
    @IBOutlet weak var fda_image: UIImageView!
    @IBOutlet weak var niosh_image: UIImageView!
    @IBOutlet weak var extra_image: UIImageView!
    
    func reload(mask: Mask) {
        self.model_label.text = mask.model
        self.company_label.text = mask.company
        
        mask.show_mask_details(delegate: self, image_zoom: true)
    }
    
    func set_extra(_ val: MaskExtra) {
        extra_label.isHidden = false
        extra_image.isHidden = false
        
        switch val {
        case .emergency_authorized:
            extra_label.text = emergency
            // extra_label.textColor = UIColor.okGreen
            set_checkmark_ok(extra_image)
        case .recalled:
            extra_label.text = recalled
            // extra_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(extra_image)
        case .revoked:
            extra_label.text = revoked
            // extra_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(extra_image)
        case .none:
            extra_label.text = ""
            extra_image.image = nil
        }
    }
    
    func set_niosh(_ val: MaskNIOSH) {
        switch val {
        case .approved:
            niosh_label.text = niosh_approved
            // niosh_label.textColor = UIColor.okGreen
            set_checkmark_ok(niosh_image)
        case .not_approved:
            niosh_label.text = niosh_not_approved
            // niosh_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(niosh_image)
        case .not_applicable:
            niosh_label.text = niosh_not_applicable
            // niosh_label.textColor = UIColor.mehGray
            set_checkmark_not_applicable(niosh_image)
        }
    }
    
    func set_fda(_ val: MaskFDA) {
        switch val {
        case .approved:
            fda_label.text = fda_approved
            // fda_label.textColor = UIColor.okGreen
            set_checkmark_ok(fda_image)
        case .not_approved:
            fda_label.text = fda_not_approved
            // fda_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(fda_image)
        }
    }
    
    func set_image(_ image: UIImage) {
        image_view.image = image
    }
    
    private func set_checkmark_not_applicable(_ label : UIImageView) {
        label.image = UIImage(systemName: "minus.circle")
        label.tintColor = UIColor.mehGray
    }
    
    private func set_checkmark_ok(_ label : UIImageView) {
        label.image = UIImage(systemName: "checkmark.circle")
        label.tintColor = UIColor.okGreen
    }
    
    private func set_checkmark_not_ok(_ label : UIImageView) {
        label.image = UIImage(systemName: "multiply.circle")
        label.tintColor = UIColor.notOkRed
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
