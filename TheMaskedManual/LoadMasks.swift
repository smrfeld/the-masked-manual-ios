//
/*
File: LoadMasks.swift
Created by: Oliver K. Ernst
Date: 11/26/20

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

extension Date {
    func daysFrom(_ date:Date) -> Int{
        return (Calendar.current as NSCalendar).components(.day, from: date, to: self, options: []).day!
    }
    
    func daysFromToday() -> Int {
        return self.daysFrom(Date())
    }
}

struct LoadMasks {
    
    static func load_masks_and_companies(completion: @escaping ([Mask], [Company]) -> Void) {
        
        if check_if_data_should_be_downloaded() {
            print("Downloading latest data...")
            download_latest_data {
                load_masks_and_companies_from_local(completion: completion)
            }
        } else {
            print("Loading data from local storage...")
            load_masks_and_companies_from_local(completion: completion)
        }
    }
    
    private static func load_masks_and_companies_from_local(completion: @escaping ([Mask], [Company]) -> Void) {
        let csn = CompanySearchName()
        let msn = ModelSearchName()
        
        get_masks_url { (url) in
            guard let url = url else {
                print("Error! Could not load masks and companies...")
                completion([],[])
                return
            }
                    
            do {
                // Load masks
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let masks = try JSONDecoder().decode(Masks.self, from: data)
                
                // Organize masks by company
                let companies = LoadMasks.organize_masks_by_company(masks.masks)
                
                // Search name for companies
                for company in companies {
                    company.search_name = csn.get_search_company_name(company_name: company.name)
                    company.search_name_words = company.search_name.components(separatedBy: " ")
                }
                
                // Search name for models
                for mask in masks.masks {
                    mask.search_model = msn.get_search_model_name(model_name: mask.model)
                    // print("Search name for mask: ", mask.model, " -> ", mask.search_model)
                }
                    
                // Callback
                completion(masks.masks, companies)
            } catch {
                // handle error
                print("Error info: \(error)")
                completion([],[])
            }
        }
    }
    
    private static func organize_masks_by_company(_ masks: [Mask]) -> [Company] {
        var companies : [Company] = []
        for mask in masks {
            let cs = companies.filter { (c) -> Bool in
                return c.name == mask.company
            }
            
            if cs.count > 0 {
                cs.first!.masks.append(mask)
                mask.company_obj = cs.first!
            } else {
                let company = Company(mask: mask)
                companies.append(company)
                mask.company_obj = company
            }
        }
        
        // Sort
        companies.sort { (c1, c2) -> Bool in
            return c1.name < c2.name
        }
        
        return companies
    }
    
    private static func check_if_data_should_be_downloaded() -> Bool {
        if let date_last_downloaded_str = UserDefaults.standard.object(forKey: "date_last_downloaded_str") as? String {
            let date_formatter = DateFormatter()
            date_formatter.dateFormat = "yyyy/MM/dd"
            if let date = date_formatter.date(from: date_last_downloaded_str) {
                if date.daysFromToday() > 7 {
                    return true
                } else {
                    // Data is still current-ish
                    return false
                }
            }
        }

        // Something wrong; better download
        return true
    }
    
    private static func mark_date_downloaded_as_today() {
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "yyyy/MM/dd"
        let date_last_downloaded_str = date_formatter.string(from: Date())
        
        UserDefaults.standard.setValue(date_last_downloaded_str, forKey: "date_last_downloaded_str")
        UserDefaults.standard.synchronize()
    }
    
    private static func get_masks_url(completion: @escaping (URL?) -> Void) {
        
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            
            let savedURL = documentsURL.appendingPathComponent("data.txt")
            completion(savedURL)
            
        } catch {
            print ("url error: \(error)")
            completion(nil)
        }
    }
    
    private static func download_latest_data(completion: @escaping () -> Void) {
        if let url = URL(string: "https://raw.githubusercontent.com/smrfeld/man-mask-python/main/data.txt?token=AD4ZKP3OV2R3IDA7IPFQQ5S7ZMMU4") {
            
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                // check for and handle errors:
                // * errorOrNil should be nil
                // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                
                // Check error
                if errorOrNil != nil || responseOrNil == nil || urlOrNil == nil {
                    print("Error downloading latest data: ", (errorOrNil?.localizedDescription ?? "Unknown"))
                    completion()
                    return
                }
                
                // Check status code
                if let response = responseOrNil as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        print("Error: status code for response is not 200: instead: ", response.statusCode)
                        completion()
                        return
                    }
                }
                
                // URL contains the URL on the local phone
                // This is temporary; must be moved to save permanently
                let fileURL = urlOrNil!
                
                // Move to permanent storage
                get_masks_url { (savedURL) in
                    guard let savedURL = savedURL else {
                        completion()
                        return
                    }

                    do {
                        
                        print("Saving data from: ", fileURL, " to: ", savedURL, " ...")
                        try? FileManager.default.removeItem(at: savedURL) // Ignores failure
                        try FileManager.default.moveItem(at: fileURL, to: savedURL)
                        print("Saved data from: ", fileURL, " to: ", savedURL)
                        
                        // Success; mark date
                        mark_date_downloaded_as_today()
                        
                        // Done!
                        completion()
                    } catch {
                        print ("file error: \(error)")
                        completion()
                    }
                }
            }
            downloadTask.resume()
            
        } else {
            completion()
        }
    }
}
