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

    private let fda_approved = "FDA-approved"
    private let fda_not_approved = "Not FDA-approved"
    private let niosh_approved = "NIOSH-approved"
    private let niosh_not_approved = "Not NIOSH-approved"
    private let niosh_not_applicable = "NIOSH approval not applicable for surgical masks"
    private let emergency = "Emergency-authorized for COVID-19"
    private let recalled = "FDA-approval potentially recalled"
    private let revoked = "Emergency authorization revoked"
    
    @IBOutlet weak var central_view: UIView!
    @IBOutlet weak var image_view: UIImageView!
    @IBOutlet weak var model_label: UILabel!
    @IBOutlet weak var company_label: UILabel!
    @IBOutlet weak var fda_label: UILabel!
    @IBOutlet weak var niosh_label: UILabel!
    @IBOutlet weak var extra_label: UILabel!
    @IBOutlet weak var extra_stack: UIStackView!
    @IBOutlet weak var fda_image: UIImageView!
    @IBOutlet weak var niosh_image: UIImageView!
    @IBOutlet weak var extra_image: UIImageView!
    @IBOutlet weak var niosh_stack: UIStackView!
    @IBOutlet weak var fda_stack: UIStackView!
    @IBOutlet weak var company_website_stack: UIStackView!
    
    @IBOutlet weak var links_stack: UIStackView!
    @IBOutlet weak var instructions_stack: UIStackView!
    @IBOutlet weak var source_stack: UIStackView!
    @IBOutlet weak var date_label: UILabel!
    
    var mask : Mask!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        
        // Bring view to front on top of blurr
        self.view.bringSubviewToFront(central_view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        // Round corners
        central_view.layer.cornerRadius = 15
        
        // Load mask details
        // model_label.text = mask.model
        // company_label.text = mask.company
        set_text_to_wrap(label: model_label, text: mask.model)
        set_text_to_wrap(label: company_label, text: mask.company)
        mask.show_mask_details(delegate: self, image_zoom: false)
        
        if mask.url_company != "" {
            company_website_stack.isHidden = false
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_url_company(recognizer:)))
            company_website_stack.addGestureRecognizer(tapGestureRecognizer)
        } else {
            company_website_stack.isHidden = true
        }
        
        if mask.url_instructions != "" {
            instructions_stack.isHidden = false
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_url_instructions(recognizer:)))
            instructions_stack.addGestureRecognizer(tapGestureRecognizer)
        } else {
            instructions_stack.isHidden = true
        }

        if mask.url_source != "" {
            source_stack.isHidden = false
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_url_source(recognizer:)))
            source_stack.addGestureRecognizer(tapGestureRecognizer)
        } else {
            source_stack.isHidden = true
        }
        
        if mask.url_instructions == "" && mask.url_source == "" {
            links_stack.isHidden = true
        } else {
            links_stack.isHidden = false
        }
        
        date_label.text = "Information last updated on: " + mask.get_date_last_updated_str()
    }
    
    @objc func open_url_source(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: mask.url_source) {
            UIApplication.shared.open(url)
        }
    }

    @objc func open_url_instructions(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: mask.url_instructions) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func open_url_company(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: mask.url_company) {
            UIApplication.shared.open(url)
        }
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
            set_text_to_wrap(label: extra_label, text: emergency)
            extra_label.textColor = UIColor.okGreen
            set_checkmark_ok(extra_image)
        case .recalled:
            extra_stack.isHidden = false
            extra_label.text = recalled
            extra_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(extra_image)
        case .revoked:
            extra_stack.isHidden = false
            extra_label.text = revoked
            extra_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(extra_image)
        }
    }
    
    func set_niosh(_ val: MaskNIOSH) {
        print(val)

        switch val {
        case .approved:
            set_text_to_wrap(label: niosh_label, text: niosh_approved)
            // niosh_label.text = niosh_approved
            niosh_label.textColor = UIColor.okGreen
            set_checkmark_ok(niosh_image)
        case .not_applicable:
            niosh_label.text = niosh_not_applicable
            niosh_label.textColor = UIColor.mehGray
            set_checkmark_not_applicable(niosh_image)
        case .not_approved:
            niosh_label.text = niosh_not_approved
            niosh_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(niosh_image)
        }
    }
    
    func set_fda(_ val: MaskFDA) {
        switch val {
        case .approved:
            fda_label.text = fda_approved
            fda_label.textColor = UIColor.okGreen
            set_checkmark_ok(fda_image)
        case .not_approved:
            fda_label.text = fda_not_approved
            fda_label.textColor = UIColor.notOkRed
            set_checkmark_not_ok(fda_image)
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
