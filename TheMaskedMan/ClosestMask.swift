//
/*
File: FindClosestMask.swift
Created by: Oliver K. Ernst
Date: 11/20/20

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

open private class Candidate : Comparable {
    let tr_str : String
    var dist : Int
    
    init(tr_str: String, dist: Int) {
        self.tr_str = tr_str
        self.dist = dist
    }
    
    public static func == (lhs: Candidate, rhs: Candidate) -> Bool {
        return lhs.dist == rhs.dist
    }

    public static func < (lhs: Candidate, rhs: Candidate) -> Bool {
        return lhs.dist < rhs.dist
    }
}

private class CandidateForCompany : Candidate, CustomStringConvertible {
    var company : Company
    
    var description: String {
        return company.name
    }
    
    init(tr_str: String, company_guess : Company) {
        self.company = company_guess
        super.init(tr_str: tr_str, dist: company_guess.distance(to: tr_str))
    }
    
    func find_closest_company(companys : [Company]) {
        company = companys.min(by: { $0.distance(to: tr_str) < $1.distance(to: tr_str) })!
        dist = company.distance(to: tr_str)
    }
}

private class CandidateForMaskModelOnly : Candidate, CustomStringConvertible {
    var mask : Mask
    
    var description: String {
        return mask.company + " : " + mask.model
    }
    
    init(tr_str: String, mask_guess : Mask) {
        self.mask = mask_guess
        super.init(tr_str: tr_str, dist: mask_guess.distance_model_only(to: tr_str))
    }
    
    func find_closest_mask(masks : [Mask]) {
        mask = masks.min(by: { $0.distance_model_only(to: tr_str) < $1.distance_model_only(to: tr_str) })!
        dist = mask.distance_model_only(to: tr_str)
    }
}

struct ClosestMask {
    
    static func find_closest_by_model_only(candidates : [String], masks : [Mask]) -> Mask? {
        if masks.count == 0 || candidates.count == 0 {
            return nil
        }
        
        let candidates_mask = candidates.map { (c) -> CandidateForMaskModelOnly in
            return CandidateForMaskModelOnly(tr_str: c, mask_guess: masks.first!)
        }

        for candidate in candidates_mask {
            candidate.find_closest_mask(masks: masks)
            print("Candidate: ", candidate.tr_str, " closest: " , candidate.mask.model, " dist: ", candidate.dist)
        }
    
        // Find closest dist
        if let closest = candidates_mask.min() {
            print("Best guess: ", closest, "  dist: ", closest.dist)
            return closest.mask
        }
        
        return nil
    }
    
    static func find_closest_company(candidates : [String], companies : [Company]) -> Company? {
        
        if companies.count == 0 || candidates.count == 0 {
            return nil
        }
        
        let candidates_company = candidates.map { (c) -> CandidateForCompany in
            return CandidateForCompany(tr_str: c, company_guess: companies.first!)
        }
        
                        
        for candidate in candidates_company {
            candidate.find_closest_company(companys: companies)
            print("Candidate: ", candidate.tr_str, " closest: " , candidate.company.name, " dist: ", candidate.dist)
        }
    
        // Find closest dist
        if let closest = candidates_company.min() {
            print("Best guess: ", closest, "  dist: ", closest.dist)
            return closest.company
        }
        
        return nil
    }
}
