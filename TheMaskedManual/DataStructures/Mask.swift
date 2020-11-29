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

private let n95_surgical_respirator = "N95 Surgical Respirator"
private let n95_respirator = "N95 Respirator"
private let surgical_mask = "Surgical Mask"

private let fda_approved = "FDA-approved"
private let fda_not_approved = "Not FDA-approved"
private let niosh_approved = "NIOSH-approved"
private let niosh_not_approved = "Not NIOSH-approved"
private let niosh_not_applicable = "NIOSH approval not applicable for surgical masks"
private let emergency = "Emergency-authorized for COVID-19"
private let recalled = "FDA-approval potentially recalled"
private let revoked = "Emergency authorization revoked"

private let fda_approved_short = "FDA"
private let fda_not_approved_short = "FDA"
private let niosh_approved_short = "NIOSH"
private let niosh_not_approved_short = "NIOSH"
private let niosh_not_applicable_short = "NIOSH"
private let emergency_short = "Emergency"
private let recalled_short = "Recalled"
private let revoked_short = "Revoked"

private let image_minus = (UIImage(systemName: "minus.circle"), UIColor.mehGray)

private let image_ok = (UIImage(systemName: "checkmark.circle"), UIColor.okGreen)

private let image_not_ok = (UIImage(systemName: "multiply.circle"), UIColor.notOkRed)

class Mask : Codable, CustomStringConvertible, Equatable, Hashable {
    
    let uuid = UUID().uuidString

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
    weak var company_obj : Company? = nil
    
    // UI fields
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    var description: String {
        return company + " : " + model
    }
    
    static func == (lhs: Mask, rhs: Mask) -> Bool {
        return lhs.uuid == rhs.uuid
        /*
        return lhs.company == rhs.company
            && lhs.model == rhs.model
            && lhs.countries_of_origin == rhs.countries_of_origin
            && lhs.respirator_type == rhs.respirator_type
            && lhs.valve_type == rhs.valve_type
         */
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

    struct MaskUI {
        var image : UIImage
        var image_zoom : UIImage
        var fda : MaskFDA
        var fda_name : String
        var fda_name_short : String
        var help_fda : String
        var niosh : MaskNIOSH
        var niosh_name : String
        var niosh_name_short : String
        var help_niosh : String
        var extra : MaskExtra
        var extra_name : String
        var extra_name_short : String
        var help_extra : String
        var type : String
        var extra_image_checkmark : (UIImage?, UIColor?)
        var fda_image_checkmark : (UIImage?, UIColor?)
        var niosh_image_checkmark : (UIImage?, UIColor?)
    }
    
    func get_mask_ui() -> MaskUI {
        switch respirator_type {
        case "SURGICAL_MASK_EUA":
            return MaskUI(
                image: get_image_surgical_mask(false),
                image_zoom: get_image_surgical_mask(true),
                fda: .not_approved,
                fda_name: fda_not_approved,
                fda_name_short: fda_not_approved_short,
                help_fda: "This surgical mask is not FDA approved.",
                niosh: .not_applicable,
                niosh_name: niosh_not_applicable,
                niosh_name_short: niosh_not_applicable_short,
                help_niosh: "National Institute for Occupational Safety and Health (NIOSH) approval is not applicable to surgical masks. It is only applicable to respirators.",
                extra: .emergency_authorized,
                extra_name: emergency,
                extra_name_short: emergency_short,
                help_extra: "This surgical mask is authorized for emergency use by the FDA during COVID-19.",
                type: surgical_mask,
                extra_image_checkmark: image_ok,
                fda_image_checkmark: image_not_ok,
                niosh_image_checkmark: image_minus
            )
        case "SURGICAL_MASK_FDA":
            return MaskUI(
                image: get_image_surgical_mask(false),
                image_zoom: get_image_surgical_mask(true),
                fda: .approved,
                fda_name: fda_approved,
                fda_name_short: fda_approved_short,
                help_fda: "This surgical mask is FDA approved.",
                niosh: .not_applicable,
                niosh_name: niosh_not_applicable,
                niosh_name_short: niosh_not_applicable_short,
                help_niosh: "National Institute for Occupational Safety and Health (NIOSH) approval is not applicable to surgical masks. It is only applicable to respirators.",
                extra: MaskExtra.none,
                extra_name: "",
                extra_name_short: "",
                help_extra: "",
                type: surgical_mask,
                extra_image_checkmark: (nil, nil),
                fda_image_checkmark: image_ok,
                niosh_image_checkmark: image_minus
            )
        case "SURGICAL_MASK_FDA_POTENTIALLY_RECALLED":
            return MaskUI(
                image: get_image_surgical_mask(false),
                image_zoom: get_image_surgical_mask(true),
                fda: .not_approved,
                fda_name: fda_not_approved,
                fda_name_short: fda_not_approved_short,
                help_fda: "This surgical mask is not FDA approved.",
                niosh: .not_approved,
                niosh_name: niosh_not_approved,
                niosh_name_short: niosh_not_approved_short,
                help_niosh: "National Institute for Occupational Safety and Health (NIOSH) approval is not applicable to surgical masks. It is only applicable to respirators.",
                extra: .recalled,
                extra_name: recalled,
                extra_name_short: recalled_short,
                help_extra: "This surgical mask has been potentially recalled by the FDA.",
                type: surgical_mask,
                extra_image_checkmark: image_not_ok,
                fda_image_checkmark: image_not_ok,
                niosh_image_checkmark: image_not_ok
            )
        case "RESPIRATOR_EUA":
            return MaskUI(
                image: get_image_respirator(false),
                image_zoom: get_image_respirator(true),
                fda: .not_approved,
                fda_name: fda_not_approved,
                fda_name_short: fda_not_approved_short,
                help_fda: "This respirator is not FDA approved. It is thereby not a surgical respirator.",
                niosh: .not_approved,
                niosh_name: niosh_not_approved,
                niosh_name_short: niosh_not_approved_short,
                help_niosh: "This respirator is not approved by the National Institute for Occupational Safety and Health (NIOSH).",
                extra: .emergency_authorized,
                extra_name: emergency,
                extra_name_short: emergency_short,
                help_extra: "This respirator is authorized for emergency use by the FDA during COVID-19.",
                type: n95_respirator,
                extra_image_checkmark: image_ok,
                fda_image_checkmark: image_not_ok,
                niosh_image_checkmark: image_not_ok
            )
        case "RESPIRATOR_EUA_EXPIRED_AUTH":
            return MaskUI(
                image: get_image_respirator(false),
                image_zoom: get_image_respirator(true),
                fda: .not_approved,
                fda_name: fda_not_approved,
                fda_name_short: fda_not_approved_short,
                help_fda: "This respirator is not FDA approved. It is thereby not a surgical respirator.",
                niosh: .not_approved,
                niosh_name: niosh_not_approved,
                niosh_name_short: niosh_not_approved_short,
                help_niosh: "This respirator is not approved by the National Institute for Occupational Safety and Health (NIOSH).",
                extra: .revoked,
                extra_name: revoked,
                extra_name_short: revoked_short,
                help_extra: "This respirator has been revoked from the list of COVID-19 emergency approved respirators by the FDA.",
                type: n95_respirator,
                extra_image_checkmark: image_not_ok,
                fda_image_checkmark: image_not_ok,
                niosh_image_checkmark: image_not_ok
            )
        case "RESPIRATOR_N95_NIOSH":
            return MaskUI(
                image: get_image_respirator(false),
                image_zoom: get_image_respirator(true),
                fda: .not_approved,
                fda_name: fda_not_approved,
                fda_name_short: fda_not_approved_short,
                help_fda: "This respirator is not FDA approved. It is thereby not a surgical respirator.",
                niosh: .approved,
                niosh_name: niosh_approved,
                niosh_name_short: niosh_approved_short,
                help_niosh: "This respirator has been approved by the National Institute for Occupational Safety and Health (NIOSH).",
                extra: MaskExtra.none,
                extra_name: "",
                extra_name_short: "",
                help_extra: "",
                type: n95_respirator,
                extra_image_checkmark: (nil,nil),
                fda_image_checkmark: image_not_ok,
                niosh_image_checkmark: image_ok
            )
        case "RESPIRATOR_N95_NIOSH_FDA":
            return MaskUI(
                image: get_image_respirator(false),
                image_zoom: get_image_respirator(true),
                fda: .approved,
                fda_name: fda_approved,
                fda_name_short: fda_approved_short,
                help_fda: "This respirator is FDA approved. It is a surgical respirator.",
                niosh: .approved,
                niosh_name: niosh_approved,
                niosh_name_short: niosh_approved_short,
                help_niosh: "This respirator has been approved by the National Institute for Occupational Safety and Health (NIOSH).",
                extra: MaskExtra.none,
                extra_name: "",
                extra_name_short: "",
                help_extra: "",
                type: n95_surgical_respirator,
                extra_image_checkmark: (nil,nil),
                fda_image_checkmark: image_ok,
                niosh_image_checkmark: image_ok
            )
        default:
            print("Warning! Respirator type not recognized: ", respirator_type)
            return MaskUI(
                image: get_image_respirator(false),
                image_zoom: get_image_respirator(true),
                fda: .not_approved,
                fda_name: "Unknown.",
                fda_name_short: "?",
                help_fda: "Unknown.",
                niosh: .not_approved,
                niosh_name: "Unknown.",
                niosh_name_short: "?",
                help_niosh: "Unknown.",
                extra: MaskExtra.none,
                extra_name: "Unknown.",
                extra_name_short: "?",
                help_extra: "Unknown.",
                type: "Unknown."
            )
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
    let url_fda : String
    let url_niosh : String
    let url_emergency : String
    let url_dev : String
}
