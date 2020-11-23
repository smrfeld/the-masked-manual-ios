//
/*
File: StringDistance.swift
Created by: Oliver K. Ernst
Date: 11/21/20

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

extension String {
    public func distance(between target: String) -> Double {
        return Double(jaroWinklerDistance(string1: self, string2: target))
    }
}
  
func jaroWinklerDistance(string1: String, string2: String) -> Double {
    var st1 = Array(string1)
    var st2 = Array(string2)
    var len1 = st1.count
    var len2 = st2.count
    if len1 < len2 {
        swap(&st1, &st2)
        swap(&len1, &len2)
    }
    if len2 == 0 {
        return len1 == 0 ? 0.0 : 1.0
    }
    let delta = max(1, len1 / 2) - 1
    var flag = Array(repeating: false, count: len2)
    var ch1Match: [Character] = []
    ch1Match.reserveCapacity(len1)
    for idx1 in 0..<len1 {
        let ch1 = st1[idx1]
        for idx2 in 0..<len2 {
            let ch2 = st2[idx2]
            if idx2 <= idx1 + delta && idx2 + delta >= idx1 && ch1 == ch2 && !flag[idx2] {
                flag[idx2] = true
                ch1Match.append(ch1)
                break
            }
        }
    }
    let matches = ch1Match.count
    if matches == 0 {
        return 1.0
    }
    var transpositions = 0
    var idx1 = 0
    for idx2 in 0..<len2 {
        if flag[idx2] {
            if st2[idx2] != ch1Match[idx1] {
                transpositions += 1
            }
            idx1 += 1
        }
    }
    let m = Double(matches)
    let jaro =
        (m / Double(len1) + m / Double(len2) + (m - Double(transpositions) / 2.0) / m) / 3.0
    var commonPrefix = 0
    for i in 0..<min(4, len2) {
        if st1[i] == st2[i] {
            commonPrefix += 1
        }
    }
    return 1.0 - (jaro + Double(commonPrefix) * 0.1 * (1.0 - jaro))
}
