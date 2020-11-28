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
    var companies : [Company] = []
    var camera_search_for_model : CameraSearchForModel!
    var camera_search_for_company : CameraSearchForCompany!
    let observed_texts = ObservedTexts()

    var mask_best_guess : Mask? = nil
    var company_best_guess : Company? = nil
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    var is_search_in_progress : Bool = false
    
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Camera search
        camera_search_for_model = CameraSearchForModel(masks: masks)
        camera_search_for_company = CameraSearchForCompany(companies: companies)
        
        // Header
        let headerNib = UINib.init(nibName: "MaskNotFoundHeaderView", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "maskNotFoundHeaderView")

        // Mask
        let maskNib = UINib.init(nibName: "MaskTableViewCell", bundle: Bundle.main)
        tableView.register(maskNib, forCellReuseIdentifier: "maskTableViewCell2")
        
        // Company
        let companyNib = UINib.init(nibName: "CompanyTableViewCell", bundle: Bundle.main)
        tableView.register(companyNib, forCellReuseIdentifier: "companyTableViewCell")
        
        // Setup video once
        setup_live_video()
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
        
        // Get observations
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("No result")
            return
        }

        // Highlight
        DispatchQueue.main.async() {
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for rg in observations {
                self.highlightWord(box: rg)
            }
        }
        
        // Only search if not currently searching
        if !is_search_in_progress {
            is_search_in_progress = true
                        
            var raw_observed_texts : [String] = []
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                // Only include terms with confidence 1
                if topCandidate.confidence > 0.5 {
                    raw_observed_texts.append(topCandidate.string)
                } else {
                    // print("Discarding: ", topCandidate.string, " for too low confidence: ", topCandidate.confidence)
                }
            }
            
            // Observed texts
            let texts = observed_texts.get_observed_texts(raw_observed_texts: raw_observed_texts)
            
            // Search for the model
            camera_search_for_model.update_candidates_with_observations(observed_texts: texts.0)
            camera_search_for_company.update_candidates_with_observations(observed_texts: texts.1)
            
            // Reload
            reload_table_with_new_guesses()
            
            // Search is done
            is_search_in_progress = false
        }
    }
    
    private func reload_table_with_new_guesses() {
        
        // Save current
        let mask_best_guess_prev = mask_best_guess
        let company_best_guess_prev = company_best_guess
        
        if let new_mask_best_guess = camera_search_for_model.get_top_mask() {
            
            // Found a new best guess for the mask
            mask_best_guess = new_mask_best_guess
            company_best_guess = nil
            
        } else if let new_company_best_guess = camera_search_for_company.get_top_company() {
        
            // Found a new best guess for the company
            mask_best_guess = nil
            company_best_guess = new_company_best_guess

        } else {

            // Truly nothing found
            mask_best_guess = nil
            company_best_guess = nil
        }
        
        // Reload if needed
        if mask_best_guess != mask_best_guess_prev || company_best_guess != company_best_guess_prev {
            DispatchQueue.main.async() {
                self.tableView.reloadData()
            }
        }
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
        // textRequest.recognitionLevel = .accurate

        // Find text rectangles
        // let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        // textRequest.reportCharacterBoxes = true
        
        self.requests = [textRequest]
    }
    
    func setup_live_video() {
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
    }
    
    func startLiveVideo() {
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

    // ***************
    // MARK: - Navigation
    // ***************
    
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchModelsSegue", let vc = segue.destination as? SearchModelViewController, let company = sender as? Company {
            vc.masks = company.masks
        }
     }
}

extension CameraViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Only show header if no best guess
        if mask_best_guess == nil && company_best_guess == nil {
            return 60.0
        } else {
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Only show header if no best guess
        if mask_best_guess == nil && company_best_guess == nil {
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
        if mask_best_guess == nil && company_best_guess == nil {
            return 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let mask = mask_best_guess {
            return get_mask_table_view_cell(mask)
            
        } else if let company = company_best_guess {
            
            if company.masks.count == 1 {
                return get_mask_table_view_cell(company.masks.first!)
            
            } else {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "companyTableViewCell") as! CompanyTableViewCell
                cell.reload(company: company)
            
                return cell
            }
        } else {
            let cell = UITableViewCell()
            return cell
        }
    }
    
    private func get_mask_table_view_cell(_ mask : Mask) -> MaskTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maskTableViewCell2") as! MaskTableViewCell
        cell.reload(mask: mask)
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let mask = mask_best_guess {
        
            // Selected mask
            clicked_mask(mask)
            
        } else if let company = company_best_guess {
            
            if company.masks.count == 1 {
                // Selected only mask
                clicked_mask(company.masks.first!)
            } else {
                self.performSegue(withIdentifier: "searchModelsSegue", sender: company)
            }
        }
    }
    
    private func clicked_mask(_ mask : Mask) {
        
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "maskDetailViewController") as! MaskDetailViewController
        alert.mask = mask
        alert.completion_on_close = {
            // Start live video and recognition again
            self.startLiveVideo()
            self.startTextDetection()
        }
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        DispatchQueue.main.async {
            // Stop live video and recognition
            self.stopLiveVideo()
            self.stopTextDetection()
            
            // Show
            self.present(alert, animated: true, completion: nil)
        }
    }
}