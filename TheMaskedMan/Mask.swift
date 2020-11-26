//
/*
File: Mask.swift
Created by: Oliver K. Ernst
Date: 11/24/20

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
import UIKit

struct ModelSearchName {

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

    static func mend_too_simple_model_names(search_model_name : String, search_company_name : String) -> String {
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

class Company : CustomStringConvertible {
    var name : String = ""
    var masks : [Mask] = []
    
    // var search_name : String
    
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

class Mask : Codable, CustomStringConvertible, Equatable {

    // Fields from JSON
    var company : String = ""
    var model : String = ""
    var countries_of_origin : [String] = []
    var respirator_type : String = ""
    var valve_type : String = ""
    var url_company : String = ""
    var url_instructions : String = ""
    var url_source : String = ""
    var date_last_updated : String = ""
    
    // Fields added later
    // MUST provide default value! Else JSON will fail
    var search_model : String = ""
    
    var description: String {
        return company + " : " + model
    }
    
    static func == (lhs: Mask, rhs: Mask) -> Bool {
        return lhs.company == rhs.company
            && lhs.model == rhs.model
            && lhs.countries_of_origin == rhs.countries_of_origin
            && lhs.respirator_type == rhs.respirator_type
            && lhs.valve_type == rhs.valve_type
    }
    
    // Keys for decoding JSON
    private enum CodingKeys : String, CodingKey {
        case company = "company"
        case model = "model"
        case countries_of_origin = "countries_of_origin"
        case respirator_type = "respirator_type"
        case valve_type = "valve_type"
        case url_company = "url_company"
        case url_instructions = "url_instructions"
        case url_source = "url_source"
        case date_last_updated = "date_last_updated"
    }
    
    func get_date_last_updated_str() -> String {
        if let date = get_date_last_updated() {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MM/dd/yyyy"
            return dateFormatter.string(from: date)
        }
        
        return "Unknown"
    }
    
    func get_date_last_updated() -> Date? {
        print(date_last_updated)
        if date_last_updated == "" {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: date_last_updated)
    }
    
    func is_surgical_mask() -> Bool {
        switch respirator_type {
        case "SURGICAL_MASK_EUA":
            return true
        case "SURGICAL_MASK_FDA":
            return true
        case "SURGICAL_MASK_FDA_POTENTIALLY_RECALLED":
            return true
        case "RESPIRATOR_EUA":
            return false
        case "RESPIRATOR_EUA_EXPIRED_AUTH":
            return false
        case "RESPIRATOR_N95_NIOSH":
            return false
        case "RESPIRATOR_N95_NIOSH_FDA":
            return false
        default:
            print("Warning! Respirator type not recognized...")
            return false
        }
    }
    
    func distance(to_mask: Mask) -> Double {
        let dist_company = self.company.distance(between: to_mask.company)
        let dist_model = self.model.distance(between: to_mask.model)
        return dist_company + dist_model
    }

    func distance(to_company: String, to_model: String) -> Double {
        let dist_company = self.company.distance(between: to_company)
        let dist_model = self.model.distance(between: to_model)
        return dist_company + dist_model
    }
    
    func distance_model_only(to_model: String) -> Double {
        return self.model.distance(between: to_model)
    }

    func distance_company_only(to_company: String) -> Double {
        return self.company.distance(between: to_company)
    }
    
    private func get_image_surgical_mask(_ image_zoom : Bool) -> UIImage {
        if image_zoom {
            return UIImage(named: "surgical_mask_zoom")!
        } else {
            return UIImage(named: "surgical_mask")!
        }
    }
    
    private func get_image_respirator(_ image_zoom : Bool) -> UIImage {
        if image_zoom {
            return UIImage(named: "respirator_zoom")!
        } else {
            return UIImage(named: "respirator")!
        }
    }

    func show_mask_details(delegate : ShowMaskDetailsProtocol, image_zoom : Bool) {
        switch respirator_type {
        case "SURGICAL_MASK_EUA":
            delegate.set_image(get_image_surgical_mask(image_zoom))
            delegate.set_fda(.approved)
            delegate.set_niosh(.not_applicable)
            delegate.set_extra(.emergency_authorized)
        case "SURGICAL_MASK_FDA":
            delegate.set_image(get_image_surgical_mask(image_zoom))
            delegate.set_fda(.approved)
            delegate.set_niosh(.not_applicable)
            delegate.set_extra(.none)
        case "SURGICAL_MASK_FDA_POTENTIALLY_RECALLED":
            delegate.set_image(get_image_surgical_mask(image_zoom))
            delegate.set_fda(.not_approved)
            delegate.set_niosh(.not_approved) // extra bad for recalls
            delegate.set_extra(.recalled)
        case "RESPIRATOR_EUA":
            delegate.set_image(get_image_respirator(image_zoom))
            delegate.set_fda(.not_approved)
            delegate.set_niosh(.not_approved)
            delegate.set_extra(.emergency_authorized)
        case "RESPIRATOR_EUA_EXPIRED_AUTH":
            delegate.set_image(get_image_respirator(image_zoom))
            delegate.set_fda(.not_approved)
            delegate.set_niosh(.not_approved)
            delegate.set_extra(.revoked)
        case "RESPIRATOR_N95_NIOSH":
            delegate.set_image(get_image_respirator(image_zoom))
            delegate.set_fda(.not_approved)
            delegate.set_niosh(.approved)
            delegate.set_extra(.none)
        case "RESPIRATOR_N95_NIOSH_FDA":
            delegate.set_image(get_image_respirator(image_zoom))
            delegate.set_fda(.approved)
            delegate.set_niosh(.approved)
            delegate.set_extra(.none)
        default:
            print("Warning! Respirator type not recognized...")
        }
    }
}

enum MaskExtra {
    case emergency_authorized, recalled, revoked, none
}

enum MaskNIOSH {
    case approved, not_approved, not_applicable
}

enum MaskFDA {
    case approved, not_approved
}

protocol ShowMaskDetailsProtocol {
    func set_extra(_ val : MaskExtra)
    func set_niosh(_ val : MaskNIOSH)
    func set_fda(_ val : MaskFDA)
    func set_image(_ image : UIImage)
}

func get_str_without_strikethrough(_ str: String) -> NSAttributedString {
    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: str)
    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributeString.length))
    return attributeString
}

func get_str_with_strikethrough(_ str: String) -> NSAttributedString {
    let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: str)
    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
    return attributeString
}

struct Masks : Decodable {
    let masks : [Mask]
}