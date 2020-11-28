//
/*
File: LoadMasks.swift
Created by: Oliver K. Ernst
Date: 11/26/20

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

import Foundation

struct LoadMasks {
    
    static func load_masks_and_companies() -> ([Mask], [Company]) {
        let csn = CompanySearchName()
        let msn = ModelSearchName()
        
        if let path = Bundle.main.path(forResource: "data", ofType: "txt") {
            do {
                // Load masks
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let masks = try JSONDecoder().decode(Masks.self, from: data)
                
                // Organize masks by company
                let companies = LoadMasks.organize_masks_by_company(masks.masks)
                
                // Search name for companies
                for company in companies {
                    company.search_name = csn.get_search_company_name(company_name: company.name)
                    company.search_name_words = company.search_name.components(separatedBy: " ")
                }
                
                // Search name for models
                for mask in masks.masks {
                    mask.search_model = msn.get_search_model_name(model_name: mask.model)
                    print("Search name for mask: ", mask.model, " -> ", mask.search_model)
                }
                                
                return (masks.masks, companies)
            } catch {
                // handle error
                print("Error info: \(error)")
            }
        }
        
        return ([],[])
    }
    
    static private func organize_masks_by_company(_ masks: [Mask]) -> [Company] {
        var companies : [Company] = []
        for mask in masks {
            let cs = companies.filter { (c) -> Bool in
                return c.name == mask.company
            }
            
            if cs.count > 0 {
                cs.first!.masks.append(mask)
                mask.company_obj = cs.first!
            } else {
                let company = Company(mask: mask)
                companies.append(company)
                mask.company_obj = company
            }
        }
        
        // Sort
        companies.sort { (c1, c2) -> Bool in
            return c1.name < c2.name
        }
        
        return companies
    }
}
