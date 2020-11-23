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
        
        switch mask.respirator_type {
        case "SURGICAL_MASK_EUA":
            set_image_surgical_mask()
            set_not_fda_approved()
            set_niosh_not_applicable()
            set_emergency_authorized()
        case "SURGICAL_MASK_FDA":
            set_image_surgical_mask()
            set_fda_approved()
            set_niosh_not_applicable()
            hide_extra_label()
        case "SURGICAL_MASK_FDA_POTENTIALLY_RECALLED":
            set_image_surgical_mask()
            set_not_fda_approved()
            set_niosh_not_applicable()
            set_recalled()
        case "RESPIRATOR_EUA":
            set_image_respirator()
            set_not_fda_approved()
            set_not_niosh_approved()
            set_emergency_authorized()
        case "RESPIRATOR_EUA_EXPIRED_AUTH":
            set_image_respirator()
            set_not_fda_approved()
            set_not_niosh_approved()
            set_revoked()
        case "RESPIRATOR_N95_NIOSH":
            set_image_respirator()
            set_not_fda_approved()
            set_niosh_approved()
            hide_extra_label()
        case "RESPIRATOR_N95_NIOSH_FDA":
            set_image_respirator()
            set_fda_approved()
            set_niosh_approved()
            hide_extra_label()
        default:
            print("Warning! Respirator type not recognized...")
        }
    }
    
    private func set_emergency_authorized() {
        extra_label.attributedText = get_str_without_strikethrough(emergency)
        extra_label.textColor = UIColor.green
    }

    private func set_recalled() {
        extra_label.attributedText = get_str_without_strikethrough(recalled)
        extra_label.textColor = UIColor.red
    }

    private func set_revoked() {
        extra_label.attributedText = get_str_without_strikethrough(revoked)
        extra_label.textColor = UIColor.red
    }
    
    private func hide_extra_label() {
        extra_label.isHidden = true
    }
    
    private func set_niosh_approved() {
        niosh_label.attributedText = get_str_without_strikethrough(niosh)
        niosh_label.textColor = UIColor.green
    }
    
    private func set_not_niosh_approved() {
        niosh_label.attributedText = get_str_with_strikethrough(niosh)
        niosh_label.textColor = UIColor.red
    }

    private func set_niosh_not_applicable() {
        niosh_label.attributedText = get_str_with_strikethrough(niosh)
        niosh_label.textColor = UIColor.gray
    }
    
    private func set_fda_approved() {
        fda_label.attributedText = get_str_without_strikethrough(fda)

        fda_label.textColor = UIColor.green
    }
    
    private func set_not_fda_approved() {
        fda_label.attributedText = get_str_with_strikethrough(fda)
        fda_label.textColor = UIColor.red
    }
    
    private func get_str_without_strikethrough(_ str: String) -> NSAttributedString {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: str)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributeString.length))
        return attributeString
    }
    
    private func get_str_with_strikethrough(_ str: String) -> NSAttributedString {
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: str)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
        return attributeString
    }

    private func set_image_surgical_mask() {
        image_view.image = UIImage(named: "surgical_mask")
    }
    
    private func set_image_respirator() {
        image_view.image = UIImage(named: "respirator")
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
