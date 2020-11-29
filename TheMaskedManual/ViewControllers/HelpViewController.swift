//
/*
File: HelpViewController.swift
Created by: Oliver K. Ernst
Date: 11/28/20

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

let url_fda = "https://www.fda.gov/medical-devices/personal-protective-equipment-infection-control/n95-respirators-surgical-masks-and-face-masks"
let url_niosh = "https://www.cdc.gov/niosh/npptl/topics/respirators/disp_part/default.html"
let url_emergency = "https://www.fda.gov/medical-devices/coronavirus-disease-2019-covid-19-emergency-use-authorizations-medical-devices/personal-protective-equipment-euas"

enum HelpField {
    case extra, fda, niosh
}

class HelpViewController: UIViewController {
    
    @IBOutlet weak var central_view: UIView!
    @IBOutlet weak var name_label: UILabel!
    @IBOutlet weak var date_label: UILabel!
    @IBOutlet weak var more_info_stack: UIStackView!
    @IBOutlet weak var content_text_view: UITextView!
    @IBOutlet weak var image_view: UIImageView!
    
    var mask : Mask!
    var mask_ui : Mask.MaskUI!
    var url : String!
    var field : HelpField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.transparent_background
        central_view.backgroundColor = UIColor.white
        
        date_label.text = "  Date last updated: " + mask.get_date_last_updated_str()
        
        switch field {
        case .extra:
            name_label.text = mask_ui.extra_name
            content_text_view.text = mask_ui.help_extra
            image_view.image = mask_ui.extra_image_checkmark.0
            image_view.tintColor = mask_ui.extra_image_checkmark.1
        case .fda:
            name_label.text = mask_ui.fda_name
            content_text_view.text = mask_ui.help_fda
            image_view.image = mask_ui.fda_image_checkmark.0
            image_view.tintColor = mask_ui.fda_image_checkmark.1
        case .niosh:
            name_label.text = mask_ui.niosh_name
            content_text_view.text = mask_ui.help_niosh
            image_view.image = mask_ui.niosh_image_checkmark.0
            image_view.tintColor = mask_ui.niosh_image_checkmark.1
        case .none:
            name_label.text = ""
            content_text_view.text = ""
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        // Round corners
        central_view.layer.cornerRadius = 15
    }
    
    @objc func open_url_fda(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: url_fda) {
            UIApplication.shared.open(url)
        }
    }

    @objc func open_url_niosh(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: url_niosh) {
            UIApplication.shared.open(url)
        }
    }

    @objc func open_url_emergency(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: url_emergency) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func close_button_pressed(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
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
