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

func set_text_to_wrap(label : UILabel, text: String) {
    label.frame = CGRect(x: 0, y: 0, width: label.frame.width, height: CGFloat.greatestFiniteMagnitude)
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.byWordWrapping
    label.text = text
    label.sizeToFit()
}

class MaskDetailViewController: UIViewController {
    
    @IBOutlet weak var type_label: UILabel!
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
    var mask_ui : Mask.MaskUI!
    var completion_on_close : () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.transparent_background
        central_view.backgroundColor = UIColor.white
        
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
        
        set_type(mask_ui.type)
        set_extra(mask_ui)
        set_niosh(mask_ui)
        set_fda(mask_ui)
        set_image(mask_ui)
        
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
        
        date_label.text = "Last updated on:\n" + mask.get_date_last_updated_str()
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

    @objc func open_help_emergency(recognizer : UITapGestureRecognizer) {
        let alert = open_help()
        alert.url = get_url_emergency()
        alert.field = .extra
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
    }

    @objc func open_help_fda(recognizer : UITapGestureRecognizer) {
        let alert = open_help()
        alert.url = get_url_fda()
        alert.field = .fda
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
    }

    @objc func open_help_niosh(recognizer : UITapGestureRecognizer) {
        let alert = open_help()
        alert.url = get_url_niosh()
        alert.field = .niosh
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    private func open_help() -> HelpViewController {
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "helpViewController") as! HelpViewController
        alert.mask = mask
        alert.mask_ui = mask_ui
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        return alert
    }
        
    func set_type(_ val: String) {
        type_label.text = val
    }
    
    func set_extra(_ mask_ui : Mask.MaskUI) {
        set_text_to_wrap(label: extra_label, text: mask_ui.extra_name)
        extra_image.image = mask_ui.extra_image_checkmark.0
        extra_image.tintColor = mask_ui.extra_image_checkmark.1
        
        switch mask_ui.extra {
        case .none:
            extra_stack.isHidden = true
        case .emergency_authorized:
            extra_stack.isHidden = false
            extra_label.textColor = UIColor.okGreen
        case .recalled:
            extra_stack.isHidden = false
            extra_label.textColor = UIColor.notOkRed
        case .revoked:
            extra_stack.isHidden = false
            extra_label.textColor = UIColor.notOkRed
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_help_emergency(recognizer:)))
        extra_stack.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func set_niosh(_ mask_ui : Mask.MaskUI) {
        set_text_to_wrap(label: niosh_label, text: mask_ui.niosh_name)
        niosh_image.image = mask_ui.niosh_image_checkmark.0
        niosh_image.tintColor = mask_ui.niosh_image_checkmark.1

        switch mask_ui.niosh {
        case .approved:
            niosh_label.textColor = UIColor.okGreen
        case .not_applicable:
            niosh_label.textColor = UIColor.mehGray
        case .not_approved:
            niosh_label.textColor = UIColor.notOkRed
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_help_niosh(recognizer:)))
        niosh_stack.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func set_fda(_ mask_ui : Mask.MaskUI) {
        fda_label.text = mask_ui.fda_name
        fda_image.image = mask_ui.fda_image_checkmark.0
        fda_image.tintColor = mask_ui.fda_image_checkmark.1

        switch mask_ui.fda {
        case .approved:
            fda_label.textColor = UIColor.okGreen
        case .not_approved:
            fda_label.textColor = UIColor.notOkRed
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.open_help_fda(recognizer:)))
        fda_stack.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func set_image(_ mask_ui : Mask.MaskUI) {
        image_view.image = mask_ui.image_zoom
    }
        
    @IBAction func close_button_pressed(_ sender: Any) {
        self.dismiss(animated: true, completion: completion_on_close)
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
