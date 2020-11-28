//
/*
File: AboutViewController.swift
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

class AboutViewController: UIViewController {

    @IBOutlet weak var scroll_view: UIScrollView!
    @IBOutlet weak var content_stack: UIStackView!
    @IBOutlet weak var text_disclaimer: UITextView!
    @IBOutlet weak var text_about_1: UITextView!
    @IBOutlet weak var text_about_2: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    }
    
    @IBAction func disclaimer_button_pressed(_ sender: Any) {
        
        // Show disclaimer
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "disclaimerNavigationController") as! UINavigationController
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /*
    func set_text_views_size_to_fit_content() {
        let text_views : [UITextView] = [
            text_disclaimer,
            text_about_1,
            text_about_2
        ]

        for text_view in text_views {
            text_view.translatesAutoresizingMaskIntoConstraints = false
            let fixedWidth = text_view.frame.size.width
            let newSize = text_view.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            print(newSize)
            text_view.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        }
    }
 */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
