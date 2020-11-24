//
/*
File: MaskDetailViewController.swift
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

class MaskDetailViewController: UIViewController, ShowMaskDetailsProtocol {

    private let fda = "FDA-approved"
    private let niosh = "NIOSH-approved"
    private let emergency = "Emergency-authorized"
    private let recalled = "Recalled"
    private let revoked = "Revoked"
    
    @IBOutlet weak var central_view: UIView!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var model_label: UILabel!
    @IBOutlet weak var company_label: UILabel!
    @IBOutlet weak var fda_labl: UILabel!
    @IBOutlet weak var niosh_label: UILabel!
    @IBOutlet weak var extra_label: UILabel!
    @IBOutlet weak var extra_stack: UIStackView!
    
    var mask : Mask!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = UIColor.clear
        
        // Round corners
        central_view.layer.cornerRadius = 5
        
        // Load mask details
        // model_label.text = mask.model
        // company_label.text = mask.company
        set_text_to_wrap(label: model_label, text: mask.model)
        set_text_to_wrap(label: company_label, text: mask.company)
        mask.show_mask_details(delegate: self, image_zoom: false)
    }
    
    private func set_text_to_wrap(label : UILabel, text: String) {
        label.frame = CGRect(x: 0, y: 0, width: label.frame.width, height: CGFloat.greatestFiniteMagnitude)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
    }
    
    func set_extra(_ val: MaskExtra) {
        switch val {
        case .none:
            extra_stack.isHidden = true
        case .emergency_authorized:
            extra_stack.isHidden = false
            extra_label.attributedText = get_str_without_strikethrough("Emergency-authorized")
            extra_label.textColor = UIColor.okGreen
        case .recalled:
            extra_stack.isHidden = false
            extra_label.attributedText = get_str_without_strikethrough("Recalled emergency auth.")
            extra_label.textColor = UIColor.notOkRed
        case .revoked:
            extra_stack.isHidden = false
            extra_label.attributedText = get_str_without_strikethrough("Revoked FDA approval")
            extra_label.textColor = UIColor.notOkRed
        }
    }
    
    func set_niosh(_ val: MaskNIOSH) {
        switch val {
        case .approved:
            niosh_label.attributedText = get_str_without_strikethrough("NIOSH-approved")
            niosh_label.textColor = UIColor.okGreen
        case .not_applicable:
            niosh_label.attributedText = get_str_without_strikethrough("NIOSH approval not applicable")
            niosh_label.textColor = UIColor.mehGray
        case .not_approved:
            niosh_label.attributedText = get_str_without_strikethrough("Not NIOSH-approved")
            niosh_label.textColor = UIColor.notOkRed
        }
    }
    
    func set_fda(_ val: MaskFDA) {
        switch val {
        case .approved:
            fda_labl.attributedText = get_str_without_strikethrough("FDA-approved")
            fda_labl.textColor = UIColor.okGreen
        case .not_approved:
            fda_labl.attributedText = get_str_without_strikethrough("Not FDA-approved")
            fda_labl.textColor = UIColor.notOkRed
        }
    }
    
    func set_image(_ image: UIImage) {
        image_view.image = image
    }
        
    @IBAction func close_button_pressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
