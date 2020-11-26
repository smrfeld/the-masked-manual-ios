//
/*
File: Company.swift
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

class Company : CustomStringConvertible, Hashable {
    
    static func == (lhs: Company, rhs: Company) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    let uuid = UUID().uuidString
    var name : String = ""
    var masks : [Mask] = []
    
    // var search_name : String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    var description: String {
        return name
    }
    
    init(name : String) {
        self.name = name
        
        // Construct search name
        // self.search_name = get_search_name(name)
    }

    convenience init(mask : Mask) {
        self.init(name: mask.company)
        self.masks.append(mask)
    }
    
    func distance(to_company: Company) -> Double {
        return self.name.distance(between: to_company.name)
    }

    func distance(to_name: String) -> Double {
        return self.name.distance(between: to_name)
    }
}
