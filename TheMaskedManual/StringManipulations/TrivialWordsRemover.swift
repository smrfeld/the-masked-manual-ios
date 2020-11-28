//
/*
File: TrivialWordsRemover.swift
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

struct TrivialWordsRemover {
    
    let trivial_words = [
        "in",
        "of",
        "and",
        "with",
        "of",
        "but",
        "in",
        "out",
        "it",
        "from",
        "when",
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
        "disposable",
        "to",
        "do",
        "yes",
        "no"
    ]
    
    func remove_trivial_words(_ name : String) -> String {
        var words = name.components(separatedBy: " ")
        words = words.filter { (x) -> Bool in
            return !trivial_words.contains(x)
        }
        return words.joined(separator: " ")
    }
    
    func remove_trivial_words(_ names : [String]) -> [String] {
        let non_trivial = names.map { (word) -> String in
            return remove_trivial_words(word)
        }
        
        // Remove empties
        let non_empty = non_trivial.filter { (word) -> Bool in
            return word != ""
        }
        
        return non_empty
    }
}
