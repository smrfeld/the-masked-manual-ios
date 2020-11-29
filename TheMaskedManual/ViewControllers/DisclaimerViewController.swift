//
/*
File: DisclaimerViewController.swift
Created by: Oliver K. Ernst
Date: 11/25/20

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

class DisclaimerViewController: UIViewController {

    @IBOutlet var content_stack: UIStackView!
    @IBOutlet weak var scroll_view: UIScrollView!
    
    @IBOutlet weak var open_fda_link: UIStackView!
    @IBOutlet weak var emergency_use_link: UIStackView!
    @IBOutlet weak var cdc_link: UIStackView!
    
    @IBOutlet weak var text_disclaimer_1: UITextView!
    @IBOutlet weak var text_disclaimer_2: UITextView!
    @IBOutlet weak var text_data_sources_1: UITextView!
    @IBOutlet weak var text_link_1: UITextView!
    @IBOutlet weak var text_link_2: UITextView!
    @IBOutlet weak var text_link_3: UITextView!
    @IBOutlet weak var text_data_sources_2: UITextView!
    @IBOutlet weak var text_data_sources_3: UITextView!
    @IBOutlet weak var text_data_sources_4: UITextView!
    @IBOutlet weak var text_privacy_1: UITextView!
    @IBOutlet weak var text_privacy_2: UITextView!
    @IBOutlet weak var text_privacy_3: UITextView!
    @IBOutlet weak var text_privacy_4: UITextView!
    @IBOutlet weak var text_privacy_5: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First text
        text_disclaimer_1.attributedText = get_first_disclaimer_bf_text()
        
        // Add stack to scroll view
        self.scroll_view.addSubview(content_stack)
        // Tell stack view we are adding constraints programmatically
        self.content_stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Bind the stackview at all sides with scroll view
        self.content_stack.leadingAnchor.constraint(equalTo: self.scroll_view.leadingAnchor).isActive = true
        self.content_stack.trailingAnchor.constraint(equalTo: self.scroll_view.trailingAnchor).isActive = true
        self.content_stack.topAnchor.constraint(equalTo: self.scroll_view.topAnchor).isActive = true
        self.content_stack.bottomAnchor.constraint(equalTo: self.scroll_view.bottomAnchor).isActive = true
        
        // Set width of stack view to match scroll
        self.content_stack.widthAnchor.constraint(equalTo: self.scroll_view.widthAnchor).isActive = true
        
        // Links
        let tap_fda = UITapGestureRecognizer(target: self, action: #selector(self.open_fda_link(recognizer:)))
        open_fda_link.addGestureRecognizer(tap_fda)
        let tap_emergency = UITapGestureRecognizer(target: self, action: #selector(self.open_emergency_link(recognizer:)))
        emergency_use_link.addGestureRecognizer(tap_emergency)
        let tap_cdc = UITapGestureRecognizer(target: self, action: #selector(self.open_cdc_link(recognizer:)))
        cdc_link.addGestureRecognizer(tap_cdc)
        
        // Fix height of text views to fit content
        set_text_views_size_to_fit_content()
    }
    
    func get_first_disclaimer_bf_text() -> NSAttributedString {
        let string = "This application is not affiliated with or endorsed by the U.S. government or any federal or state agency." as NSString
        let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14.0)])
        let boldFontAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14.0)]
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: "not affiliated with or endorsed by the U.S. government or any federal or state agency."))

        return attributedString
    }
    
    @objc func open_fda_link(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: get_url_data_fda()) {
            UIApplication.shared.open(url)
        }
    }

    @objc func open_emergency_link(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: get_url_data_emergency()) {
            UIApplication.shared.open(url)
        }
    }

    @objc func open_cdc_link(recognizer : UITapGestureRecognizer) {
        if let url = URL(string: get_url_data_niosh()) {
            UIApplication.shared.open(url)
        }
    }
    
    func set_text_views_size_to_fit_content() {
        let text_views : [UITextView] = [
            text_disclaimer_1,
            text_disclaimer_2,
            text_data_sources_1,
            text_data_sources_2,
            text_data_sources_3,
            text_data_sources_4,
            text_link_1,
            text_link_2,
            text_link_3,
            text_privacy_1,
            text_privacy_2,
            text_privacy_3,
            text_privacy_4,
            text_privacy_5
        ]

        for text_view in text_views {
            let fixedWidth = text_view.frame.size.width
            let newSize = text_view.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            text_view.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        }
    }
    
    @IBAction func agree_button_pressed(_ sender: Any) {
        // Dismiss
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
