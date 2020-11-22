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

protocol ClosestMaskProtocol {
    static func find_closest_mask_by_company_only(candidates : [String], masks : [Mask], max_no : Int) -> [Mask]
    static func find_closest_mask_by_model_only(candidates : [String], masks : [Mask], max_no : Int) -> [Mask]
    static func find_closest_company(candidates : [String], companies : [Company], max_no : Int) -> [Company]
    static func find_closest_mask_by_company_then_model(candidates : [String], companies : [Company], max_no : Int) -> [Mask]
}

struct ClosestMask : ClosestMaskProtocol {
    
    static func find_closest_mask_by_company_only(candidates : [String], masks : [Mask], max_no : Int) -> [Mask] {
        let closest_candidates = ClosestMask.find_closest_mask_candidate_by_company_only(candidates: candidates, masks: masks, max_no: max_no)
        let closest_masks = closest_candidates.map { (c) -> Mask in
            return c.mask
        }
        
        return closest_masks
    }
    
    static func find_closest_mask_by_model_only(candidates : [String], masks : [Mask], max_no : Int) -> [Mask] {
        let closest_candidates = ClosestMask.find_closest_mask_candidate_by_model_only(candidates: candidates, masks: masks, max_no: max_no)
        let closest_masks = closest_candidates.map { (c) -> Mask in
            return c.mask
        }
        
        return closest_masks
    }
    
    static func find_closest_company(candidates : [String], companies : [Company], max_no : Int) -> [Company] {
        let closest_candidates = ClosestMask.find_closest_candidate_for_company(candidates: candidates, companies: companies, max_no: max_no)
        let closest_companies = closest_candidates.map { (c) -> Company in
            return c.company
        }

        return closest_companies
    }
    
    static func find_closest_mask_by_company_then_model(candidates : [String], companies : [Company], max_no : Int) -> [Mask] {
        // Closest companies
        let closest_candidates_for_companies = ClosestMask.find_closest_candidate_for_company(candidates: candidates, companies: companies, max_no: 5)
        
        // Compile list of masks from these companies
        var closest_masks : [CandidateForMask] = []
        for candidate_for_company in closest_candidates_for_companies {
            closest_masks += ClosestMask.find_closest_mask_candidate_by_model_and_company(candidates_for_model: candidates, candidate_for_company: candidate_for_company.candidate_for_company, masks: candidate_for_company.company.masks, max_no: 3)
        }
 
        // Find the closest masks
        closest_masks.sort()
        print(closest_masks)
        let no_masks_max = min(max_no, closest_masks.count)
        let closest_candidates : [CandidateForMask] = closest_masks.dropLast(closest_masks.count - no_masks_max)
        return closest_candidates.map { (c) -> Mask in
            return c.mask
        }
    }
    
    // ***************
    // MARK: - Private
    // ***************
    
    private static func find_closest_mask_candidate_by_company_only(candidates : [String], masks : [Mask], max_no : Int) -> [CandidateForMask] {
        
        if masks.count == 0 || candidates.count == 0 {
            return []
        }
        
        var candidates_mask = candidates.map { (c) -> CandidateForMask in
            return CandidateForMask(candidate_for_model: "", candidate_for_company: c, mask_guess: masks.first!)
        }

        for candidate in candidates_mask {
            candidate.find_closest_mask_by_company_only(masks: masks)
            print("Candidate for company: ", candidate.candidate_for_company, " closest: " , candidate.mask.model, " dist: ", candidate.dist)
        }
    
        // Sort by distance
        candidates_mask.sort()
        let no_masks_max = min(max_no, candidates_mask.count)
        let closest_candidates : [CandidateForMask] = candidates_mask.dropLast(candidates_mask.count - no_masks_max)
        return closest_candidates
    }
    
    private static func find_closest_mask_candidate_by_model_only(candidates : [String], masks : [Mask], max_no : Int) -> [CandidateForMask] {
        if masks.count == 0 || candidates.count == 0 {
            return []
        }
        
        var candidates_mask = candidates.map { (c) -> CandidateForMask in
            return CandidateForMask(candidate_for_model: c, candidate_for_company: "", mask_guess: masks.first!)
        }

        for candidate in candidates_mask {
            candidate.find_closest_mask_by_model_only(masks: masks)
            print("Candidate for model: ", candidate.candidate_for_model, " closest: " , candidate.mask.model, " dist: ", candidate.dist)
        }
    
        // Sort by distance
        candidates_mask.sort()
        let no_masks_max = min(max_no, candidates_mask.count)
        let closest_candidates : [CandidateForMask] = candidates_mask.dropLast(candidates_mask.count - no_masks_max)
        return closest_candidates
    }
    
    private static func find_closest_mask_candidate_by_model_and_company(candidates_for_model : [String], candidate_for_company : String, masks : [Mask], max_no : Int) -> [CandidateForMask] {
        if masks.count == 0 || candidates_for_model.count == 0 || candidate_for_company == "" {
            return []
        }
        
        var candidates_mask = candidates_for_model.map { (c) -> CandidateForMask in
            return CandidateForMask(candidate_for_model: c, candidate_for_company: candidate_for_company, mask_guess: masks.first!)
        }

        for candidate in candidates_mask {
            candidate.find_closest_mask_by_company_and_model(masks: masks, candidate_for_company: candidate_for_company)
            print("Candidate for model: ", candidate.candidate_for_model, " candidate for company: ", candidate.candidate_for_company, " closest: " , candidate.mask.model, " dist: ", candidate.dist)
        }
    
        // Sort by distance
        candidates_mask.sort()
        let no_masks_max = min(max_no, candidates_mask.count)
        let closest_candidates : [CandidateForMask] = candidates_mask.dropLast(candidates_mask.count - no_masks_max)
        return closest_candidates
    }
    
    private static func find_closest_candidate_for_company(candidates : [String], companies : [Company], max_no : Int) -> [CandidateForCompany] {
        
        if companies.count == 0 || candidates.count == 0 {
            return []
        }
        
        var candidates_company = candidates.map { (c) -> CandidateForCompany in
            return CandidateForCompany(candidate_for_company: c, company_guess: companies.first!)
        }
        
                        
        for candidate in candidates_company {
            candidate.find_closest_company(companies: companies)
            print("Candidate company: ", candidate.candidate_for_company, " closest: " , candidate.company.name, " dist: ", candidate.dist)
        }
    
        // Sort by distance
        candidates_company.sort()
        let no_masks_max = min(max_no, candidates_company.count)
        let closest_candidates : [CandidateForCompany] = candidates_company.dropLast(candidates_company.count - no_masks_max)
        return closest_candidates
    }
}

open class Candidate : Comparable {
    var dist : Double
    
    init(dist: Double) {
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
    var candidate_for_company : String
    var company : Company
    
    var description: String {
        return company.name + ": " + String(dist)
    }
    
    init(candidate_for_company: String, company_guess : Company) {
        self.candidate_for_company = candidate_for_company
        self.company = company_guess
        super.init(dist: company_guess.distance(to_name: candidate_for_company))
    }
    
    func find_closest_company(companies : [Company]) {
        company = companies.min(by: { $0.distance(to_name: candidate_for_company) < $1.distance(to_name: candidate_for_company) })!
        dist = company.distance(to_name: candidate_for_company)
    }
}

private class CandidateForMask : Candidate, CustomStringConvertible {
    var candidate_for_model : String
    var candidate_for_company : String
    var mask : Mask
    
    var description: String {
        return mask.company + ": " + mask.model + ": " + String(dist)
    }
    
    init(candidate_for_model: String, candidate_for_company: String, mask_guess : Mask) {
        self.candidate_for_model = candidate_for_model
        self.candidate_for_company = candidate_for_company
        self.mask = mask_guess
        super.init(dist: mask_guess.distance(to_company: candidate_for_company, to_model: candidate_for_model))
    }
    
    func find_closest_mask_by_model_only(masks : [Mask]) {
        mask = masks.min(by: { $0.distance_model_only(to_model: candidate_for_model) < $1.distance_model_only(to_model: candidate_for_model) })!
        dist = mask.distance_model_only(to_model: candidate_for_model)
    }

    func find_closest_mask_by_company_only(masks : [Mask]) {
        mask = masks.min(by: { $0.distance_company_only(to_company: candidate_for_company) < $1.distance_company_only(to_company: candidate_for_company) })!
        dist = mask.distance_company_only(to_company: candidate_for_company)
    }

    func find_closest_mask_by_company_and_model(masks : [Mask], candidate_for_company : String) {
        mask = masks.min(by: { $0.distance(to_company: candidate_for_company, to_model: candidate_for_model) < $1.distance(to_company: candidate_for_company, to_model: candidate_for_model) })!
        dist = mask.distance(to_company: candidate_for_company, to_model: candidate_for_model)
    }
}
