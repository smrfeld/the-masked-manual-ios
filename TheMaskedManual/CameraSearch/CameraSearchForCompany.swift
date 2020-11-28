//
/*
File: CameraSearchForCompany.swift
Created by: Oliver K. Ernst
Date: 11/27/20

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

protocol CameraSearchForCompanyProtocol {
    mutating func update_candidates_with_observations(observed_texts : [String])
    func get_top_company(min_weight : Float) -> Company?
}

struct CameraSearchForCompany : CameraSearchForCompanyProtocol {
    
    private var companies : [Company] = []
    private var company_candidates : [Company : MyCandidate] = [:]

    init(companies : [Company]) {
        self.companies = companies
    }
    
    mutating func update_candidates_with_observations(observed_texts : [String]) {

        // Collect weights
        let weights = collect_normalized_weights_for_companies(observed_texts: observed_texts)
        
        // Ensure all observed masks have a candidate
        ensure_candidates_exist_for_company(weights: weights)
        
        // Add observations for all candidates
        for (company_candidate, candidate) in company_candidates {
            if let weight = weights[company_candidate] {
                // There exists an observation for this candidate
                candidate.add_observation(weight)
            } else {
                // No observation right now
                // "Expire" old observations i.e. get smaller = less important
                candidate.expire_observations_if_exist()
            }
        }
    }
    
    func get_top_company(min_weight : Float = 0.5) -> Company? {
                            
        // Possibly good enough guess for company
        // Find top company
        let top_company = company_candidates.max { (c1, c2) -> Bool in
            return c1.value.get_weight() < c2.value.get_weight()
        }
        
        if let top_company = top_company, top_company.value.get_weight() > min_weight {
            return top_company.key
        } else {
        
            // Truly nothing found
            return nil
        }
    }
    
    private func print_top_company() {
        
        let cs = company_candidates.sorted { (c1, c2) -> Bool in
            return c1.value.get_weight() > c2.value.get_weight()
        }
        
        print("Top 3 company candidates:")
        var i = 0
        for (company, candidate) in cs {
            print(company.name, " ~ ", company.search_name, ": weight: ", candidate.get_weight())
            
            i += 1
            if i == 3 {
                break
            }
        }
    }
    
    private func collect_normalized_weights_for_companies(observed_texts : [String]) -> [Company : Float] {
        
        var weights : [Company : Float] = [:]
        for observed_text in observed_texts {
            
            // Must contain the whole word
            let companies_filtered = companies.filter({ (company) -> Bool in
                return company.search_name_words.contains(observed_text)
            })
            
            for company in companies_filtered {
                let weight = 1.0 / Float(company.search_name_words.count)
                if weights[company] == nil {
                    weights[company] = 0.0
                }
                weights[company]! += weight
            }
        }
        
        return weights
    }
    
    private mutating func ensure_candidates_exist_for_company(weights : [Company : Float]) {
        
        // Ensure all observed masks have a candidate
        for (company, _) in weights {
            if company_candidates[company] == nil {
                company_candidates[company] = MyCandidate()
            }
        }
    }
}
