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
import FuzzyMatchingSwift

private let opts = FuzzyMatchOptions(threshold: 0.5, distance: 0)
private let max_dist : Int = 1000000000000

class Company : CustomStringConvertible {
    var name : String = ""
    var masks : [Mask] = []
    
    var description: String {
        return name
    }
    
    init(name : String) {
        self.name = name
    }

    convenience init(mask : Mask) {
        self.init(name: mask.company)
        self.masks.append(mask)
    }
    
    func distance(to other: Company) -> Int {
        return name.fuzzyMatchPattern(other.name, loc: nil, options: opts) ?? max_dist
    }

    func distance(to name: String) -> Int {
        return name.fuzzyMatchPattern(name, loc: nil, options: opts) ?? max_dist
    }
}

class Mask : Decodable, CustomStringConvertible {
    var company : String = ""
    var model : String = ""
    
    var description: String {
        return company + " : " + model
    }

    func distance(to other: Mask) -> Int {
        let dist_company = company.fuzzyMatchPattern(other.company, loc: nil, options: opts) ?? max_dist
        let dist_model = model.fuzzyMatchPattern(other.model, loc: nil, options: opts) ?? max_dist
        return dist_company + dist_model
    }

    func distance(to company: String, model: String) -> Int {
        let dist_company = self.company.fuzzyMatchPattern(company, loc: nil, options: opts) ?? max_dist
        let dist_model = self.model.fuzzyMatchPattern(model, loc: nil, options: opts) ?? max_dist
        return dist_company + dist_model
    }
    
    func distance_model_only(to model: String) -> Int {
        return self.model.fuzzyMatchPattern(model, loc: nil, options: opts) ?? max_dist
    }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load masks
        masks = load_masks()
        companies = organize_masks_by_company(masks)
        
        var candidates : [String] = ["3M"]
        if let closest_company = ClosestMask.find_closest_company(candidates: candidates, companies: companies) {
            
            candidates = ["9001"]
            if let closest_mask = ClosestMask.find_closest_by_model_only(candidates: candidates, masks: closest_company.masks) {
                //...
            }
        }
        
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
        
    }
            
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var candidates : [String] = []
            
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                
                detectedText += topCandidate.string
                detectedText += "\n"
                
                candidates.append(topCandidate.string)
            }
            
            let closest_company = ClosestMask.find_closest_company(candidates: candidates, companies: self.companies)
            
            DispatchQueue.main.async {
                print(detectedText)
            }
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
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

