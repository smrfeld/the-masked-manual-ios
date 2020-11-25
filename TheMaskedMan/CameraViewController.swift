//
/*
File: CameraViewController.swift
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

import UIKit
import Vision
import VisionKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var masks : [Mask] = []
    
    @IBOutlet weak var text_view: UITextView!
    // @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    // var is_search_in_progress : Bool = false
    
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startLiveVideo()
        startTextDetection()
    }
    
    override func viewDidLayoutSubviews() {
        // Fix the fact that view is not finished in viewDidAppear
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    private func ammend_candidates(raw_candidates : [String]) -> [String] {
        var candidates = raw_candidates
        
        // Get search words
        // Removes nonsense characters and trivial phrases
        candidates = candidates.map({ (c) -> String in
            return get_search_name(c)
        })
        
        // Remove anything less than 2 characters
        var i = 0
        while i < candidates.count {
            if candidates[i].count < 2 {
                candidates.remove(at: i)
            } else {
                i += 1
            }
        }
        
        // Add all words
        for i in 0..<candidates.count {
            let words = candidates[i].components(separatedBy: " ")
            
            // Only add words if more than one word
            if words.count != 1 {
                for word in words {
                    // Only add if the word has more than 2 characters
                    if word.count >= 2 {
                        candidates.append(word)
                    }
                }
            }
        }
        
        // For every candidate, also try stripping any leading or trailing zeros if they exist
        for i in 0..<candidates.count {
            if candidates[i].first! == "0" {
                candidates.append(String(candidates[i].dropFirst()))
            }
            
            if candidates[i].last! == "0" {
                candidates.append(String(candidates[i].dropLast()))
            }
        }
        
        // Remove duplicates (ruins ordering!)
        candidates = Array(Set(candidates))
        
        return candidates
    }
    
    private func search_for_model(raw_candidates : [String]) {
        
        // Ammend and fix list of candidates
        let candidates = ammend_candidates(raw_candidates: raw_candidates)
        
        print("Candidates")
        print(candidates)
        
        for candidate in candidates {
            
            let masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.search_model.contains(candidate)
            })
            print(candidate, " ", masks_filtered.map({ (m) -> String in
                return m.search_model
            }))
        }
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("No result")
            return
        }
        
        var candidates : [String] = []
        
        print("--- Found: ---")
        var text = ""
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { return }
            print(topCandidate.string)
            text += topCandidate.string + "\n"
            candidates.append(topCandidate.string)
        }
        DispatchQueue.main.async() {
            self.text_view.text = text
        }
        
        // Search for the model
        search_for_model(raw_candidates: candidates)
        
        DispatchQueue.main.async() {
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for rg in observations {
                self.highlightWord(box: rg)
            }
        }
        
        // Text boxes
        /*
         
        guard let observations = request.results else {
            print("no result")
            return
        }

        let result = observations.map({$0 as? VNTextObservation})
        
        DispatchQueue.main.async() {
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
         */
    }
        
    func highlightWord(box: VNRecognizedTextObservation) {
        let rect = box.boundingBox
            
        let xCord = rect.maxX * imageView.frame.size.width
        let yCord = (1 - rect.minY) * imageView.frame.size.height
        let width = (rect.minX - rect.maxX) * imageView.frame.size.width
        let height = (rect.minY - rect.maxY) * imageView.frame.size.height
            
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
            
        imageView.layer.addSublayer(outline)
    }
    
    func startTextDetection() {
        // Find text
        let textRequest = VNRecognizeTextRequest(completionHandler: self.detectTextHandler)
        textRequest.recognitionLevel = .fast

        // Find text rectangles
        // let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        // textRequest.reportCharacterBoxes = true
        
        self.requests = [textRequest]
    }
    
    func startLiveVideo() {
        // Init capture session
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        // Setup
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
           
        // Set image
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
            
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
                
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
            
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
            
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
            
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
