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

class MaskTableViewCell: UITableViewCell {
        
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
    
    @IBOutlet weak var stack_view: UIStackView!
        
    func reload(mask : Mask, mask_ui : Mask.MaskUI, rounded : Bool) {

        backgroundColor = .white
        if rounded {
            layer.cornerRadius = 15
        } else {
            layer.cornerRadius = 0
        }
        
        self.model_label.text = mask.model
        self.company_label.text = mask.company
        set_extra(mask_ui)
        set_niosh(mask_ui)
        set_fda(mask_ui)
        set_image(mask_ui)
    }
        
    func set_extra(_ mask_ui : Mask.MaskUI) {
        extra_label.isHidden = false
        extra_image.isHidden = false
        
        extra_image.image = mask_ui.extra_image_checkmark.0
        extra_image.tintColor = mask_ui.extra_image_checkmark.1

        extra_label.text = mask_ui.extra_name_short
    }
    
    func set_niosh(_ mask_ui : Mask.MaskUI) {
        niosh_label.text = mask_ui.niosh_name_short
        niosh_image.image = mask_ui.niosh_image_checkmark.0
        niosh_image.tintColor = mask_ui.niosh_image_checkmark.1
    }
    
    func set_fda(_ mask_ui : Mask.MaskUI) {
        fda_label.text = mask_ui.fda_name_short
        fda_image.image = mask_ui.fda_image_checkmark.0
        fda_image.tintColor = mask_ui.fda_image_checkmark.1
    }
    
    func set_image(_ mask_ui : Mask.MaskUI) {
        image_view.image = mask_ui.image
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
