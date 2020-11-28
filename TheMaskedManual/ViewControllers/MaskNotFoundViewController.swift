//
/*
File: MaskNotFoundViewController.swift
Created by: Oliver K. Ernst
Date: 11/24/20

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

class MaskNotFoundViewController: UIViewController {
    
    @IBOutlet weak var central_view: UIView!
    @IBOutlet weak var first_text_view: UITextView!
    @IBOutlet weak var second_text_view: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.transparent_background
        central_view.backgroundColor = UIColor.white
        
        // Bring view to front on top of blurr
        self.view.bringSubviewToFront(central_view)
        
        // Text
        first_text_view.text = "Your mask was not found in our system."
        second_text_view.text = "Your mask is:\n"
            + "(1) Not FDA approved, and\n"
            + "(2) Not NIOSH approved, and\n"
            + "(3) Not authorized by the FDA for emergency"
            + "  use in response to Covid-19.\n"
            + "\n"
            + "It is therefore possible that your mask's\n"
            + "effectiveness is unvalidated."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Round corners
        central_view.layer.cornerRadius = 15
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
