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
    func get_search_model_name(model_name : String) -> String
}

struct ModelSearchName : ModelSearchNameProtocol {

    let trivial_words_remover = TrivialWordsRemover()
    
    private static func remove_too_simple_model_names(_ search_model_name : String) -> String {
        
        // Too simple
        let too_simple = [
            "surgical",
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
        
        // Also: if name is only a few characters and contains n95
        if too_simple.contains(search_model_name) || (search_model_name.count < 5 && search_model_name.contains("n95")) {
            // Must remove!
            return ""
        } else {
            // OK!
            return search_model_name
        }
    }

    nonmutating func get_search_model_names(model_names : [String]) -> [String] {
        let names = model_names.map { (c) -> String in
            return get_search_model_name(model_name: c)
        }
        let non_zero = names.filter { (c) -> Bool in
            return c != ""
        }
        
        return non_zero
    }
    
    nonmutating func get_search_model_name(model_name : String) -> String {
        var ret = model_name
        
        // Lowercase
        ret = ret.lowercased()
        
        // Replace some things with spaces
        ret = ReplaceBadCharsWithSpaces.replace_bad_chars_with_spaces(ret)
        
        // Remove everything except:
        // letters
        // numbers
        // space
        ret = ret.filter("0123456789abcdefghijklmnopqrstuvwxyz -".contains)

        // Remove bad words
        ret = trivial_words_remover.remove_trivial_words(ret)
        
        // Remove anything less than 2 characters
        ret = ShortWordsRemover.remove_words_less_than_two_chars(ret)
        
        // Remove too simple
        ret = ModelSearchName.remove_too_simple_model_names(ret)
        
        // print("Search name for: <", name, "> is: <", ret, ">")
        
        return ret
    }
}
