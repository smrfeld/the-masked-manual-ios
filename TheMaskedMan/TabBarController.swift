//
/*
File: TabBarController.swift
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

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // About by default
        self.selectedIndex = 1;
        
        // Load masks
        let masks = load_masks()
        var companies = organize_masks_by_company(masks)
        companies.sort { (c1, c2) -> Bool in
            return c1.name < c2.name
        }
        
        // Send to VCs
        if let nvc = self.viewControllers?[0] as? UINavigationController {
            if let vc = nvc.topViewController as? CameraViewController {
                vc.masks = masks
            }
        }
        if let nvc = self.viewControllers?[2] as? UINavigationController {
            if let vc = nvc.topViewController as? SearchCompanyViewController {
                vc.masks = masks
                vc.companies = companies
           }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show disclaimer
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "disclaimerNavigationController") as! UINavigationController
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    // ***************
    // MARK: - Load masks
    // ***************
    
    private func load_masks() -> [Mask] {
        if let path = Bundle.main.path(forResource: "data", ofType: "txt") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let masks = try JSONDecoder().decode(Masks.self, from: data)
                print(masks)
                
                // Search name for models
                for mask in masks.masks {
                    mask.search_model = get_search_name(mask.model)
                    print("Search name for mask: ", mask.model, " -> ", mask.search_model)
                }
                
                return masks.masks
            } catch {
                // handle error
                print("Error info: \(error)")
            }
        }
        
        return []
    }
    
    private func organize_masks_by_company(_ masks: [Mask]) -> [Company] {
        var companies : [Company] = []
        for mask in masks {
            let cs = companies.filter { (c) -> Bool in
                return c.name == mask.company
            }
            
            if cs.count > 0 {
                cs.first!.masks.append(mask)
            } else {
                companies.append(Company(mask: mask))
            }
        }
        
        return companies
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
