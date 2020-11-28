//
/*
File: CompanySearchName.swift
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

protocol CompanySearchNameProtocol {
    func get_search_company_name(company_name : String) -> String
}

struct CompanySearchName : CompanySearchNameProtocol {
    
    let trivial_words_remover = TrivialWordsRemover()

    nonmutating func get_search_company_names(company_names : [String]) -> [String] {
        let names = company_names.map { (c) -> String in
            return get_search_company_name(company_name: c)
        }
        let non_zero = names.filter { (c) -> Bool in
            return c != ""
        }
        
        return non_zero
    }
    
    nonmutating func get_search_company_name(company_name : String) -> String {
        var ret = company_name
        
        // Lowercase
        ret = ret.lowercased()
        
        // Replace some things with spaces
        ret = ReplaceBadCharsWithSpaces.replace_bad_chars_with_spaces(ret)

        // Remove everything except:
        // letters
        // numbers
        // space
        ret = ret.filter("0123456789abcdefghijklmnopqrstuvwxyz ".contains)

        // Remove bad words
        ret = trivial_words_remover.remove_trivial_words(ret)
        
        // Remove anything less than 2 characters
        ret = ShortWordsRemover.remove_words_less_than_two_chars(ret)

        // print("Search name for: <", name, "> is: <", ret, ">")
        
        return ret
    }
}
