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
    var camera_search : CameraSearch!
    var mask_best_guess : Mask? = nil
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    // var is_search_in_progress : Bool = false
    
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Camera search
        camera_search = CameraSearch(masks)
        
        // Header
        let headerNib = UINib.init(nibName: "MaskNotFoundHeaderView", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "maskNotFoundHeaderView")

        // Mask
        let maskNib = UINib.init(nibName: "MaskTableViewCell", bundle: Bundle.main)
        tableView.register(maskNib, forCellReuseIdentifier: "maskTableViewCell2")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startLiveVideo()
        startTextDetection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLiveVideo()
        stopTextDetection()
    }
    
    override func viewDidLayoutSubviews() {
        // Fix the fact that view is not finished in viewDidAppear
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("No result")
            return
        }
        
        var raw_observed_texts : [String] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { return }
            raw_observed_texts.append(topCandidate.string)
        }
        
        // Search for the model
        camera_search.update_candidates_with_observations(raw_observed_texts: raw_observed_texts)
        
        // Set best mask
        if let new_best_guess = camera_search.get_top_mask() {
            if new_best_guess != mask_best_guess {
                mask_best_guess = new_best_guess
                
                // Reload table
                DispatchQueue.main.async() {
                    self.tableView.reloadData()
                }
            }
        }
        
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
    
    func stopTextDetection() {
        self.requests = []
    }
    
    func stopLiveVideo() {
        session.stopRunning()
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
        imageLayer.bounds = imageView.bounds
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
    
    // ***************
    // MARK: - Tap not found header
    // ***************
    
    @objc func handleTapMaskNotFound(_ sender: UITapGestureRecognizer) {
        
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "maskNotFoundViewController") as! MaskNotFoundViewController
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
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

extension CameraViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Only show header if no best guess
        if mask_best_guess == nil {
            return 60.0
        } else {
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Only show header if no best guess
        if mask_best_guess == nil {
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "maskNotFoundHeaderView") as! MaskNotFoundHeaderView
            
            // Add tap
            let tap = UITapGestureRecognizer(target: self, action:#selector(self.handleTapMaskNotFound(_:)))
            view.addGestureRecognizer(tap)
            
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Only show rows if best guess
        if mask_best_guess == nil {
            return 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maskTableViewCell2") as! MaskTableViewCell
        if let mask = mask_best_guess {
            cell.reload(mask: mask)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show
        if let mask = mask_best_guess {
        
            let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "maskDetailViewController") as! MaskDetailViewController
            alert.mask = mask
            alert.providesPresentationContextTransitionStyle = true
            alert.definesPresentationContext = true
            alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
