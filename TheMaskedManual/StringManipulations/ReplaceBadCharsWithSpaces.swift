//
/*
File: ReplaceBadCharsWithSpaces.swift
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

struct ReplaceBadCharsWithSpaces {
    
    static func replace_bad_chars_with_spaces(_ word : String) -> String {
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
    
    static func replace_bad_chars_with_spaces(_ words : [String]) -> [String] {
        let words_rep = words.map { (word) -> String in
            return ReplaceBadCharsWithSpaces.replace_bad_chars_with_spaces(word)
        }
        let non_zero = words_rep.filter { (word) -> Bool in
            return word != ""
        }
        
        return non_zero
    }
}
