//
/*
 File: ViewController.swift
 Created by: Oliver K. Ernst
 Date: 11/20/20
 
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

import UIKit
import Vision
import VisionKit
import Fuzzywuzzy_swift

// threshold in FuzzyMatchOptions defines how strict you want to be when fuzzy matching. A value of 0.0 is equivalent to an exact match. A value of 1.0 indicates a very loose understanding of whether a match has been found.
// distance in FuzzyMatchOptions defines where in the host String to look for the pattern.

// private let opts = FuzzyMatchOptions(threshold: 0.5, distance: 0)
private let max_dist : Double = 0.999

/*
extension String {
    func distance(_ other : String) -> Double {
        // A Double which indicates how confident we are that the pattern can be found in the host string. A low value (0.001) indicates that the pattern is likely to be found. A high value (0.999) indicates that the pattern is not likely to be found
        return self.confidenceScore(other) ?? max_dist
    }
}
*/

private func get_search_name(_ name : String) -> String {
    var ret = name
    
    // Lowercase
    ret = ret.lowercased()
    
    // Remove commas and periods
    ret = ret.replacingOccurrences(of: ".", with: "")
    ret = ret.replacingOccurrences(of: ",", with: "")
    ret = ret.replacingOccurrences(of: "(", with: "")
    ret = ret.replacingOccurrences(of: ")", with: "")
    ret = ret.replacingOccurrences(of: "[", with: "")
    ret = ret.replacingOccurrences(of: "]", with: "")
    ret = ret.replacingOccurrences(of: "&", with: "")
    ret = ret.replacingOccurrences(of: "®", with: "")

    // Remove bad words
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
        "kgaa"
    ]
    let ret_words = ret.components(separatedBy: " ")
    ret = ret_words.filter { !bad_words.contains($0) }.joined(separator: " ")
    
    print("Search name for: <", name, "> is: <", ret, ">")
    
    return ret
}
 
class Company : CustomStringConvertible {
    var name : String = ""
    var masks : [Mask] = []
    
    var search_name : String
    
    var description: String {
        return name
    }
    
    init(name : String) {
        self.name = name
        
        // Construct search name
        self.search_name = get_search_name(name)
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

class Mask : Decodable, CustomStringConvertible {
    var company : String = ""
    var model : String = ""
    let countries_of_origin : [String]
    let respirator_type : String
    let valve_type : String
    let url_company : String
    let url_instructions : String
    let url_source : String
    let date_last_updated : String
        
    var description: String {
        return company + " : " + model + " - " + respirator_type + " - " + url_company + " - " + url_instructions + " - " + date_last_updated
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

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    var masks : [Mask] = []
    var companies : [Company] = []
    
    private func load_masks() -> [Mask] {
        if let path = Bundle.main.path(forResource: "data", ofType: "txt") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let masks = try JSONDecoder().decode(Masks.self, from: data)
                return masks.masks
            } catch {
                // handle error
                print("Error info: \(error)")
            }
        }
        
        return []
    }
    
    private func organize_masks_by_company(_ masks: [Mask]) -> [Company] {
        var companies : [Company] = []
        for mask in masks {
            let cs = companies.filter { (c) -> Bool in
                return c.name == mask.company
            }
            
            if cs.count > 0 {
                cs.first!.masks.append(mask)
            } else {
                companies.append(Company(mask: mask))
            }
        }
        
        return companies
    }
    
    private func test_find() {
        
        /*
        var candidates : [String] = ["3M","antsheism","3Meotnuh"]
        if let closest_company = ClosestMask.find_closest_company(candidates: candidates, companies: companies) {
            
            candidates = ["9001","101"]
            if let closest_mask = ClosestMask.find_closest_by_model_only(candidates: candidates, masks: closest_company.masks).first {
                //...
            }
        }
         */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load masks
        masks = load_masks()
        companies = organize_masks_by_company(masks)
        
        // Test
        // test_find()
        
        // Do any additional setup after loading the view.
        setupVision()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func scan_button_pressed(_ sender: Any) {
        
        // Show scanner
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
        
        /*
        if let path = Bundle.main.path(forResource: "IMG_4409", ofType: "JPG") {
            if let image = UIImage(contentsOfFile: path) {
                processImage(image)
            }
        }
         */
    }
            
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var candidates : [String] = []
            
            // var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                // print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                
                // detectedText += topCandidate.string
                // detectedText += "\n"
                
                // Exclude confidence under 0.5
                if topCandidate.confidence < 0.5 {
                    continue
                }
                
                // Exclude single character guesses
                if topCandidate.string.count <= 1 {
                    continue
                }
                            
                candidates.append(topCandidate.string)
            }
            
            print("--- Closest mask by company then model ---")
            let closest_masks = ClosestMask.find_closest_mask_by_company_then_model(candidates: candidates, companies: self.companies, max_no: 10)
            print(closest_masks)

            print("--- Closest mask by model only ---")
            let closest_masks_by_model = ClosestMask.find_closest_mask_by_model_only(candidates: candidates, masks: self.masks, max_no: 10)
            print(closest_masks_by_model)
            
            DispatchQueue.main.async {
                print(candidates)
            }
        }
        
        textRecognitionRequest.recognitionLevel = .fast
    }
    
    private func processImage(_ image: UIImage) {
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
        
        processImage(newImage)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
              let reloadedImage = UIImage(data: imageData) else {
            return originalImage
        }
        return reloadedImage
    }
    
}

