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






extension String {
    public func distance(between target: String) -> Double {
        return Double(jaroWinklerDistance(string1: self, string2: target))
    }
}








import Foundation
 
func loadDictionary(_ path: String) throws -> [String] {
    let contents = try String(contentsOfFile: path, encoding: String.Encoding.ascii)
    return contents.components(separatedBy: "\n")
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
 
func withinDistance(words: [String], maxDistance: Double, string: String,
                    maxToReturn: Int) -> [(String, Double)] {
    var arr = Array(words.map{($0, jaroWinklerDistance(string1: string, string2: $0))}
        .filter{$0.1 <= maxDistance})
    arr.sort(by: { x, y in return x.1 < y.1 })
    return Array(arr[0..<min(maxToReturn, arr.count)])
}
 
func pad(string: String, width: Int) -> String {
    if string.count >= width {
        return string
    }
    return String(repeating: " ", count: width - string.count) + string
}






















/*



import Foundation

func sort(s1:String, s2:String) -> (String, String) {
    if s1.count <= s2.count {
        return (s1, s2)
    }

    return (s2, s1)
}

public func JaroWinklerDistance(in_s1:String, in_s2:String) -> Float {
    let (s1, s2) = sort(s1: in_s1.lowercased(), s2: in_s2.lowercased())

    if s1.count == 1 || s2.count == 1 {
        return 0
    }

    var m = 0, t = 0, l = 0

    let window = floor(Float(max(s1.count, s2.count)) / 2 - 1)

    let s1_array = Array(s1)
    let s2_array = Array(s2)
    var idx = 0

    for char1 in s1 {
        if char1 == s2_array[idx] {
            m += 1

            if idx == l && idx < 4 {
                l += 1
            }
        } else {
            if s2_array.contains(char1) {
                let gap = s2_array.firstIndex(of: char1)! - idx
                
                if gap <= Int(window) {
                    m += 1

                    for k in idx..<s1_array.count {
                        if s2_array.contains(s1_array[k]) {
                            if s2_array.firstIndex(of: s1_array[k])! <= idx {
                                t += 1
                            }
                        }
                    }
                }
            }
        }

        idx += 1
    }

    let distanceFirst = Float(m)/Float(s1.count) + Float(m)/Float(s2.count)
    let distanceSecond = (Float(m)-floor(Float(t)/Float(2)))/Float(m)
    let distance = (distanceFirst + distanceSecond) / Float(3)
    let jwd = distance + (Float(l) * Float(0.1) * (Float(1) - distance))

    return jwd
}



*/
















/*

import Foundation

extension String {
    func index(_ i: Int) -> String.Index {
        if i >= 0 {
            return self.index(self.startIndex, offsetBy: i)
        } else {
            return self.index(self.endIndex, offsetBy: i)
        }
    }

    subscript(i: Int) -> Character? {
        if i >= count || i < -count {
            return nil
        }

        return self[index(i)]
    }

    subscript(r: Range<Int>) -> String {
        return String(self[index(r.lowerBound)..<index(r.upperBound)])
    }

    /// Get distance between target. (alias of `distanceJaroWinkler(between:)`.)
    /// - Parameter target: The target `String`.
    /// - Returns: The Jaro-Winkler distance between the receiver and `target`.
    public func distance(between target: String) -> Double {
        return distanceJaroWinkler(between: target)
    }

    /// Get Damerau-Levenshtein distance.
    ///
    /// Reference <https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance#endnote_itman#Distance_with_adjacent_transpositions>
    /// - Parameter target: The target `String`.
    /// - Returns: The Damerau-Levenshtein distance between the receiver and `target`.
    public func distanceDamerauLevenshtein(between target: String) -> Int {
        let selfCount = self.count
        let targetCount = target.count

        if self == target {
            return 0
        }
        if selfCount == 0 {
            return targetCount
        }
        if targetCount == 0 {
            return selfCount
        }

        var da: [Character: Int] = [:]

        var d = Array(repeating: Array(repeating: 0, count: targetCount + 2), count: selfCount + 2)

        let maxdist = selfCount + targetCount
        d[0][0] = maxdist
        for i in 1...selfCount + 1 {
            d[i][0] = maxdist
            d[i][1] = i - 1
        }
        for j in 1...targetCount + 1 {
            d[0][j] = maxdist
            d[1][j] = j - 1
        }

        for i in 2...selfCount + 1 {
            var db = 1

            for j in 2...targetCount + 1 {
                let k = da[target[j - 2]!] ?? 1
                let l = db

                var cost = 1
                if self[i - 2] == target[j - 2] {
                    cost = 0
                    db = j
                }

                let substition = d[i - 1][j - 1] + cost
                let injection = d[i][j - 1] + 1
                let deletion = d[i - 1][j] + 1
                let selfIdx = i - k - 1
                let targetIdx = j - l - 1
                let transposition = d[k - 1][l - 1] + selfIdx + 1 + targetIdx

                d[i][j] = Swift.min(
                    substition,
                    injection,
                    deletion,
                    transposition
                )
            }

            da[self[i - 2]!] = i
        }

        return d[selfCount + 1][targetCount + 1]
    }


    /// Get Hamming distance.
    ///
    /// Note: Only applicable when string lengths are equal.
    ///
    /// Reference <https://en.wikipedia.org/wiki/Hamming_distance>.
    /// - Parameter target: The target `String`.
    /// - Returns: The Hamming distance between the receiver and `target`.
    public func distanceHamming(between target: String) -> Int {
        assert(self.count == target.count)

        return zip(self, target).filter { $0 != $1 }.count
    }

    /// Get Jaro-Winkler distance.
    ///
    /// (Score is normalized such that 0 equates to no similarity and 1 is an exact match).
    ///
    /// Reference <https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance>
    /// - Parameter target: The target `String`.
    /// - Returns: The Jaro-Winkler distance between the receiver and `target`.
    public func distanceJaroWinkler(between target: String) -> Double {
        var stringOne = self
        var stringTwo = target
        if stringOne.count > stringTwo.count {
            stringTwo = self
            stringOne = target
        }

        let stringOneCount = stringOne.count
        let stringTwoCount = stringTwo.count

        if stringOneCount == 0 && stringTwoCount == 0 {
            return 1.0
        }

        let matchingDistance = stringTwoCount / 2
        var matchingCharactersCount: Double = 0
        var transpositionsCount: Double = 0
        var previousPosition = -1

        // Count matching characters and transpositions.
        for (i, stringOneChar) in stringOne.enumerated() {
            for (j, stringTwoChar) in stringTwo.enumerated() {
                if max(0, i - matchingDistance)..<min(stringTwoCount, i + matchingDistance) ~= j {
                    if stringOneChar == stringTwoChar {
                        matchingCharactersCount += 1
                        if previousPosition != -1 && j < previousPosition {
                            transpositionsCount += 1
                        }
                        previousPosition = j
                        break
                    }
                }
            }
        }

        if matchingCharactersCount == 0.0 {
            return 0.0
        }

        // Count common prefix (up to a maximum of 4 characters)
        let commonPrefixCount = min(max(Double(self.commonPrefix(with: target).count), 0), 4)

        let jaroSimilarity = (matchingCharactersCount / Double(stringOneCount) + matchingCharactersCount / Double(stringTwoCount) + (matchingCharactersCount - transpositionsCount) / matchingCharactersCount) / 3

        // Default is 0.1, should never exceed 0.25 (otherwise similarity score could exceed 1.0)
        let commonPrefixScalingFactor = 0.1

        return jaroSimilarity + commonPrefixCount * commonPrefixScalingFactor * (1 - jaroSimilarity)
    }

    /// Get the Levenshtein distance.
    ///
    /// Reference <https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows>
    /// - Parameter target: The target `String`.
    /// - Returns: The Levenshtein distance between the receiver and `target`.
    public func distanceLevenshtein(between target: String) -> Int {
        let selfCount = self.count
        let targetCount = target.count

        if self == target {
            return 0
        }
        if selfCount == 0 {
            return targetCount
        }
        if targetCount == 0 {
            return selfCount
        }

        // The previous row of distances
        var v0 = [Int](repeating: 0, count: targetCount + 1)
        // Current row of distances.
        var v1 = [Int](repeating: 0, count: targetCount + 1)
        // Initialize v0.
        // Edit distance for empty self.
        for i in 0..<v0.count {
            v0[i] = i
        }

        for (i, selfCharacter) in self.enumerated() {
            // Calculate v1 (current row distances) from previous row v0

            // Edit distance is delete (i + 1) chars from self to match empty t.
            v1[0] = i + 1

            // Use formula to fill rest of the row.
            for (j, targetCharacter) in target.enumerated() {
                let cost = selfCharacter == targetCharacter ? 0 : 1
                v1[j + 1] = Swift.min(
                    v1[j] + 1,
                    v0[j + 1] + 1,
                    v0[j] + cost
                )
            }

            // Copy current row to previous row for next iteration.
            for j in 0..<v0.count {
                v0[j] = v1[j]
            }
        }

        return v1[targetCount]
    }

    /// Get most frequent K distance.
    ///
    /// Reference <https://web.archive.org/web/20191117082524/https://en.wikipedia.org/wiki/Most_frequent_k_characters>
    /// - Parameters:
    ///   - target: The target `String`.
    ///   - K: The number of most frequently occuring characters to use for the similarity comparison.
    ///   - maxDistance: The maximum distance limit (defaults to a value of 10 if not provided).
    public func distanceMostFreqK(between target: String, K: Int, maxDistance: Int = 10) -> Int {
        return maxDistance - mostFrequentKSimilarity(characterFrequencyHashOne: self.mostFrequentKHashing(K),
                                                     characterFrequencyHashTwo: target.mostFrequentKHashing(K))
    }

    /// Get normalized most frequent K distance.
    ///
    /// (Score is normalized such that 0 equates to no similarity and 1 is an exact match).
    ///
    /// Reference <https://www.semanticscholar.org/paper/A-high-performance-approach-to-string-similarity-K-Valdestilhas-Soru/2ce037c9b5d77972af6892c170396c82d883dab9>
    /// - Parameters:
    ///   - target: The target `String`.
    ///   - k: The number of most frequently occuring characters to use for the similarity comparison.
    /// - Returns: The normalized most frequent K distance between the receiver and `target`.
    public func distanceNormalizedMostFrequentK(between target: String, k: Int) -> Double {
        let selfMostFrequentKHash = self.mostFrequentKHashing(k)
        let targetMostFrequentKHash = target.mostFrequentKHashing(k)
        let commonCharacters = Set(selfMostFrequentKHash.keys).intersection(Set(targetMostFrequentKHash.keys))

        // Return early if there are no common characters between the two hashes
        guard commonCharacters.isEmpty == false else {
            return 0.0
        }

        let similarity = commonCharacters.reduce(0) { characterCountSum, character -> Int in
            characterCountSum + selfMostFrequentKHash[character]! + targetMostFrequentKHash[character]!
        }

        return Double(similarity) / Double(self.count + target.count)
    }

    // MARK: - Private methods

    /// Get a hash of character-frequency pairs for the receiver.
    ///
    /// If two characters have the same frequency, then favour the one that occurs first in the receiver.
    /// - Parameters:
    ///   - k: The maximum number of character-frequency pairs to include in the returned hash.
    /// - Returns: a `Dictionary` hash of the most frequent characters in the receiver.
    private func mostFrequentKHashing(_ k: Int) -> [Character: Int] {
        let characterFrequencies = self.reduce(into: [Character: Int]()) { characterFrequencies, character in
            characterFrequencies[character] = (characterFrequencies[character] ?? 0) + 1
        }

        let sortedFrequencies = characterFrequencies.sorted { (characterFrequencies1, characterFrequencies2) -> Bool in
            // If frequencies are equal, sort against character index in receiver
            if characterFrequencies1.value == characterFrequencies2.value {
                return self.firstIndex(of: characterFrequencies1.key)! < self.firstIndex(of: characterFrequencies2.key)!
            }
            return characterFrequencies1.value > characterFrequencies2.value
        }
        // If receiver is shorter than `K` characters, use `sortedFrequencies.count`
        let clampedK = min(k, sortedFrequencies.count)

        return sortedFrequencies[0..<clampedK].reduce(into: [Character: Int]()) { mostFrequentKHash, characterFrequencyPair in
            mostFrequentKHash[characterFrequencyPair.key] = characterFrequencyPair.value
        }
    }

    /// Get the similarity measure between two character-frequency `Dictionary` hashes.
    /// - Parameters:
    ///   - characterFrequencyHashOne: a `Dictionary` hash returned from `mostFrequentKHashing(_ k: Int)` for a particular `String`.
    ///   - characterFrequencyHashTwo: a `Dictionary` hash returned from `mostFrequentKHashing(_ k: Int)` for a different `String`.
    private func mostFrequentKSimilarity(characterFrequencyHashOne: [Character: Int], characterFrequencyHashTwo: [Character: Int]) -> Int {

        let commonCharacters = Set(characterFrequencyHashOne.keys).intersection(Set(characterFrequencyHashTwo.keys))

        // Return early if there are no common characters between the two hashes
        guard commonCharacters.isEmpty == false else {
            return 0
        }

        return commonCharacters.reduce(0) { characterCountSum, character -> Int in
            characterCountSum + characterFrequencyHashOne[character]!
        }
    }
}
 
*/
