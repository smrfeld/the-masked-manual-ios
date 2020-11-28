//
/*
File: ObservedTexts.swift
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

struct ObservedTexts {
    
    let model_search_name = ModelSearchName()
    let company_search_name = CompanySearchName()
        
    nonmutating func get_observed_texts(raw_observed_texts : [String]) -> ([String],[String]) {
        
        // Split into words
        let observed_texts = split_into_words(raw_observed_texts: raw_observed_texts)
        
        // Get search words
        // Removes nonsense characters and trivial phrases
        var model_observed_texts = model_search_name.get_search_model_names(model_names: observed_texts)
        var company_observed_texts = company_search_name.get_search_company_names(company_names: observed_texts)

        // Remove any nonsense words we can identify
        remove_nonsense_words(observed_texts: &model_observed_texts)
        remove_nonsense_words(observed_texts: &company_observed_texts)

        // For every candidate, also try stripping any leading or trailing chars if they exist
        add_texts_with_stripped_leading_trailing_bad_chars(observed_texts: &model_observed_texts)
        add_texts_with_stripped_leading_trailing_bad_chars(observed_texts: &company_observed_texts)

        // Remove duplicates (ruins ordering!)
        model_observed_texts = Array(Set(model_observed_texts))
        company_observed_texts = Array(Set(company_observed_texts))

        return (model_observed_texts, company_observed_texts)
    }
    
    private nonmutating func remove_nonsense_words(observed_texts : inout [String]) {
        
        var bad_strs : [String] = []
        // Three in a row of any chraacter
        for char in "abcdefghijklmnopqrstuvwxyz" {
            bad_strs.append(String(char) + String(char) + String(char))
        }
        // Double i, j, n, b
        bad_strs += ["ii", "jj", "nn", "bb"]
        
        let bad_chars = ["i", "j"]
        
        // For some reason, many words have lots of "i" or "j" - these can be removed
        var i = 0
        while i < observed_texts.count {
            
            var remove = false
            
            // Remove bad strs
            for bad_str in bad_strs {
                if observed_texts[i].contains(bad_str) {
                    remove = true
                    break
                }
            }

            // Next if needed
            if remove {
                observed_texts.remove(at: i)
                continue
            }
            
            // Remove too many occurences of same char
            for bad_char in bad_chars {
                let no_occurences = observed_texts[i].components(separatedBy: bad_char).count - 1
                if no_occurences >= 3 {
                    remove = true
                    break
                }
            }
            
            // Next if needed
            if remove {
                observed_texts.remove(at: i)
                continue
            }
            
            // Next
            i += 1
        }
    }
        
    private nonmutating func split_into_words(raw_observed_texts: [String]) -> [String] {
                
        var ret : [String] = []
        let no = raw_observed_texts.count
        for i in 0..<no {
            let words = raw_observed_texts[i].components(separatedBy: [" ", "-", "/", "&", ".", ",", ";", ":"])
            
            for word in words {
                ret.append(word)
            }
        }
        
        return ret
    }
    
    private nonmutating func add_texts_with_stripped_leading_trailing(observed_texts : inout [String]) {
                
        let no = observed_texts.count
        for i in 0..<no {
            let s = String(observed_texts[i].dropFirst())
            if s.count > 2 {
                observed_texts.append(s)
            }
              
            let r = String(observed_texts[i].dropLast())
            if r.count > 2 {
                observed_texts.append(r)
            }
        }
    }
    
    private nonmutating func add_texts_with_stripped_leading_trailing_bad_chars(observed_texts : inout [String]) {
        
        let bad_chars = ["0", "*", "/", "-", "?"]
        
        let no = observed_texts.count
        for i in 0..<no {
            var s = observed_texts[i]

            // Remove all bad chars from the front
            var no_remove_front = 0
            for char in s {
                if bad_chars.contains(String(char)) {
                    // Remove!
                    no_remove_front += 1
                } else {
                    // Done
                    break
                }
            }
            
            if no_remove_front > 0 {
                s = String(s.dropFirst(no_remove_front))
            }
            
            // Remove all bad chars from the back
            var no_remove_back = 0
            for char in s.reversed() {
                if bad_chars.contains(String(char)) {
                    // Remove
                    no_remove_back += 1
                } else {
                    // Done
                    break
                }
            }
            
            if no_remove_back > 0 {
                s = String(s.dropLast(no_remove_back))
            }
            
            // Append if the string is changed
            if s != observed_texts[i] {
                observed_texts.append(s)
            }
        }
    }
}
