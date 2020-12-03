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

    @IBOutlet weak var table_view_height_constraint: NSLayoutConstraint!
    
    var is_search_in_progress : Bool = false
    
    var session = AVCaptureSession()
    var deviceInput : AVCaptureInput? = nil
    var deviceOutput : AVCaptureOutput? = nil
    var requests = [VNRequest]()

    private var screenshot_mode = false
    
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
                
        if screenshot_mode {
            imageView.image = UIImage(named: "toy_image")
            
            mask_best_guess = masks.filter({ (m) -> Bool in
                return m.model == "7048"
            }).first!
            
            self.table_view_height_constraint.constant = 120.0
            self.tableView.layoutIfNeeded()
        }
        
        // Background color
        tableView.backgroundColor = UIColor(red: 174.0/256.0, green: 174.0/256.0, blue: 178.0/256.0, alpha: 1.0)
        
        // Setup image once
        setup_image_once()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        start_up()
    }
    
    private func start_up() {
        if !screenshot_mode {
            let success = setup_live_video()
            
            if success {
                startLiveVideo()
                startTextDetection()
            }
        }
    }
    
    private func shut_down() {
        if !screenshot_mode {
            stopLiveVideo()
            stopTextDetection()
            
            break_down_live_video()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        shut_down()
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
        
        // Only search if not currently searching
        if !is_search_in_progress {
            is_search_in_progress = true
            
            // Highlight
            DispatchQueue.main.async() {
                self.imageView.layer.sublayers?.removeSubrange(1...)
                for rg in observations {
                    self.highlightWord(box: rg)
                }
            }
            
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
                
                // Fix height
                if self.mask_best_guess != nil {
                    // Set height to two cells
                    self.table_view_height_constraint.constant = 120.0
                    self.tableView.layoutIfNeeded()
                    
                } else if self.company_best_guess != nil {
                    // Set height to two cells
                    self.table_view_height_constraint.constant = 120.0
                    self.tableView.layoutIfNeeded()
                    
                } else {
                    // Set height to one cells
                    self.table_view_height_constraint.constant = 60.0
                    self.tableView.layoutIfNeeded()
                }
                
                // Reload table
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
        print("Stopping live video...")
        if session.isRunning {
            session.stopRunning()
        }
        print("Stopped live video.")
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
    
    func setup_live_video() -> Bool {
        print("setup live video start...")
        
        // Init capture session
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("No camera device")
            return false
        }
                
        // Setup
        do {
            let deviceInput_ = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(deviceInput_)
            deviceInput = deviceInput_
        } catch {
            print("Error: ", error.localizedDescription)
            return false
        }
        
        let deviceOutput_ = AVCaptureVideoDataOutput()
        deviceOutput_.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput_.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addOutput(deviceOutput_)
        deviceOutput = deviceOutput_
                   
        print("setup live video.")

        return true
    }
    
    private func setup_image_once() {
        // Set image
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
    }
    
    func break_down_live_video() {
        print("Breaking down live video...")
        
        // Remove IO
        if let deviceInput = deviceInput {
            session.removeInput(deviceInput)
        }
        if let deviceOutput = deviceOutput {
            session.removeOutput(deviceOutput)
        }
        deviceOutput = nil
        deviceInput = nil
        
        print("Broke down live video.")
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
    
    @objc func handleTapSeeMoreMasksByThisCompany(_ sender: UITapGestureRecognizer) {
        if let mask_best_guess = mask_best_guess {
            self.performSegue(withIdentifier: "searchModelsSegue", sender: mask_best_guess.company_obj)
        }
    }

    @objc func handleTapMaskNotFound(_ sender: UITapGestureRecognizer) {
        
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "maskNotFoundViewController") as! MaskNotFoundViewController
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        alert.completion_on_close = {
            // Start live video and recognition again
            self.start_up()
        }

        DispatchQueue.main.async {
            // Stop live video and recognition
            self.shut_down()

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
        if mask_best_guess != nil {
            return 2
        } else if company_best_guess != nil {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if mask_best_guess != nil {
            if section == 0 {
                return 0.0
            } else {
                return 60.0
            }
        } else if company_best_guess != nil {
            if section == 0 {
                return 0.0
            } else {
                return 60.0
            }
        } else {
            return 60.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if mask_best_guess != nil {
            if section == 0 {
                return nil
            } else {
                return get_see_more_masks_by_this_company_header_view()
            }
        } else if company_best_guess != nil {
            if section == 0 {
                return nil
            } else {
                return get_mask_not_found_header_view()
            }
        } else {
            return get_mask_not_found_header_view()
        }
    }
    
    private func get_see_more_masks_by_this_company_header_view() -> MaskNotFoundHeaderView {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "maskNotFoundHeaderView") as! MaskNotFoundHeaderView
        view.show_see_more_masks(mask: mask_best_guess)
        
        // Add tap
        let tap = UITapGestureRecognizer(target: self, action:#selector(self.handleTapSeeMoreMasksByThisCompany(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    private func get_mask_not_found_header_view() -> MaskNotFoundHeaderView {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "maskNotFoundHeaderView") as! MaskNotFoundHeaderView
        view.show_cant_find_your_mask()

        // Add tap
        let tap = UITapGestureRecognizer(target: self, action:#selector(self.handleTapMaskNotFound(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mask_best_guess != nil {
            if section == 0 {
                return 1
            } else {
                return 0
            }
        } else if company_best_guess != nil {
            if section == 0 {
                return 1
            } else {
                return 0
            }
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
                cell.reload(company: company, rounded: true)
            
                return cell
            }
        } else {
            return UITableViewCell()
        }
    }
    
    private func get_mask_table_view_cell(_ mask : Mask) -> MaskTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maskTableViewCell2") as! MaskTableViewCell
        cell.reload(mask: mask, mask_ui: mask.get_mask_ui(), rounded: true)
    
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
        alert.mask_ui = mask.get_mask_ui()
        alert.completion_on_close = {
            // Start live video and recognition again
            self.start_up()
        }
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        DispatchQueue.main.async {
            // Stop live video and recognition
            self.shut_down()
            
            // Show
            self.present(alert, animated: true, completion: nil)
        }
    }
}
