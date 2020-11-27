//
/*
File: ModelSearchName.swift
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

import Foundation

protocol ModelSearchNameProtocol {
    static func get_search_model_name(model_name : String) -> String
    static func mend_too_simple_model_names(search_model_name : String, search_company_name : String?) -> String
}

struct ModelSearchName : ModelSearchNameProtocol {

    private static func remove_words_less_than_two_chars(_ word : String) -> String {
        var ret = word
        
        var ret_words2 = ret.components(separatedBy: " ")
        var i = 0
        while i < ret_words2.count {
            if ret_words2[i].count < 2 {
                ret_words2.remove(at: i)
            } else {
                i += 1
            }
        }
        ret = ret_words2.joined(separator: " ")
        
        return ret
    }

    private static func remove_bad_words(_ word : String) -> String {
        let bad_words = [
            "co",
            "ltd",
            "ltda",
            "limited",
            "coltd",
            "inc",
            "intl",
            "llc",
            "corp",
            "and",
            "ag",
            "kgaa",
            "part",
            "number",
            "surgical",
            "face",
            "mask",
            "model",
            "facemask",
            "masks",
            "models",
            "professional",
            "tm",
            "safety",
            "non-sterile",
            "medical",
            "surgical-disposable",
            "protection",
            "kit",
            "personal",
            "disposable"
        ]
        let ret_words = word.components(separatedBy: " ")
        let ret = ret_words.filter { !bad_words.contains($0) }.joined(separator: " ")
        
        return ret
    }

    private static func replace_bad_chars_with_spaces(_ word : String) -> String {
        var ret = word
        
        // Replace some things with spaces
        let should_be_space = [",",".","/","(",")",";",":"]
        for sbs in should_be_space {
            ret = ret.replacingOccurrences(of: sbs, with: " ")
        }
        
        // Fix double spaces
        ret = ret.replacingOccurrences(of: "  ", with: " ")

        return ret
    }

    static func mend_too_simple_model_names(search_model_name : String, search_company_name : String?) -> String {
        guard let search_company_name = search_company_name else {
            print("Warning: search_company_name is nil!")
            return search_model_name
        }
        
        // Too simple
        let too_simple = [
            "surgical mask",
            "mask surgical",
            "mask",
            "facemask",
            "respirator",
            "face-mask",
            "surgical-mask",
            "protective-mask",
            "protective mask"
        ]
        
        if too_simple.contains(search_model_name) || (search_model_name.count < 8 && search_model_name.contains("n95")) {
            // Must fix!
            let ret = search_company_name + " " + search_model_name
            return ret
        } else {
            // OK!
            return search_model_name
        }
    }

    static func get_search_model_name(model_name : String) -> String {
        var ret = model_name
        
        // Lowercase
        ret = ret.lowercased()
        
        // Replace some things with spaces
        ret = ModelSearchName.replace_bad_chars_with_spaces(ret)
        
        // Remove everything except:
        // letters
        // numbers
        // space
        ret = ret.filter("0123456789abcdefghijklmnopqrstuvwxyz -".contains)

        // Remove bad words
        ret = ModelSearchName.remove_bad_words(ret)
        
        // Remove anything less than 2 characters
        ret = ModelSearchName.remove_words_less_than_two_chars(ret)
        
        // print("Search name for: <", name, "> is: <", ret, ">")
        
        return ret
    }
}
