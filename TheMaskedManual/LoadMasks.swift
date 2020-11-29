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

func get_url_fda() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_fda") as? String, url != "" {
        return url
    } else {
        return "https://www.fda.gov/medical-devices/personal-protective-equipment-infection-control/n95-respirators-surgical-masks-and-face-masks"
    }
}

func get_url_data_fda() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_data_fda") as? String, url != "" {
        return url
    } else {
        return "https://open.fda.gov"
    }
}

func get_url_niosh() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_niosh") as? String, url != "" {
        return url
    } else {
        return "https://www.cdc.gov/niosh/npptl/topics/respirators/disp_part/default.html"
    }
}

func get_url_data_niosh() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_data_niosh") as? String, url != "" {
        return url
    } else {
        return "https://www.fda.gov/medical-devices/coronavirus-disease-2019-covid-19-emergency-use-authorizations-medical-devices/personal-protective-equipment-euas"
    }
}

func get_url_emergency() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_emergency") as? String, url != "" {
        return url
    } else {
        return "https://www.fda.gov/medical-devices/coronavirus-disease-2019-covid-19-emergency-use-authorizations-medical-devices/personal-protective-equipment-euas"
    }
}

func get_url_data_emergency() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_data_emergency") as? String, url != "" {
        return url
    } else {
        return "https://www.cdc.gov/niosh/npptl/"
    }
}

func get_url_dev() -> String {
    if let url = UserDefaults.standard.object(forKey: "url_dev") as? String, url != "" {
        return url
    } else {
        return "https://github.com/smrfeld/the-masked-manual-ios"
    }
}


func set_url_fda(_ url : String) {
    if url == "" {
        return
    }
    
    UserDefaults.standard.setValue(url, forKey: "url_fda")
    UserDefaults.standard.synchronize()
}

func set_url_data_fda(_ url : String) {
    if url == "" {
        return
    }
    
    UserDefaults.standard.setValue(url, forKey: "url_data_fda")
    UserDefaults.standard.synchronize()
}

func set_url_niosh(_ url : String) {
    if url == "" {
        return
    }

    UserDefaults.standard.setValue(url, forKey: "url_niosh")
    UserDefaults.standard.synchronize()
}

func set_url_data_niosh(_ url : String) {
    if url == "" {
        return
    }

    UserDefaults.standard.setValue(url, forKey: "url_data_niosh")
    UserDefaults.standard.synchronize()
}

func set_url_emergency(_ url : String) {
    if url == "" {
        return
    }

    UserDefaults.standard.setValue(url, forKey: "url_emergency")
    UserDefaults.standard.synchronize()
}

func set_url_data_emergency(_ url : String) {
    if url == "" {
        return
    }

    UserDefaults.standard.setValue(url, forKey: "url_data_emergency")
    UserDefaults.standard.synchronize()
}

func set_url_dev(_ url : String) {
    if url == "" {
        return
    }

    UserDefaults.standard.setValue(url, forKey: "url_dev")
    UserDefaults.standard.synchronize()
}

struct LoadMasks {
    
    static func load_masks_and_companies(completion: @escaping ([Mask], [Company]) -> Void) {
        
        // Load current data
        load_masks_and_companies_from_local(completion: completion)
        
        // Also: check if data should be downloaded, and if so, download asynch
        if check_if_data_should_be_downloaded() {
            print("Downloading latest data...")
            download_latest_data(completion: {})
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
                
                set_url_dev(masks.url_dev)
                set_url_fda(masks.url_fda)
                set_url_niosh(masks.url_niosh)
                set_url_emergency(masks.url_emergency)
                set_url_data_fda(masks.url_fda)
                set_url_data_niosh(masks.url_niosh)
                set_url_data_emergency(masks.url_emergency)

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
            
            // Try the backup
            if let path = Bundle.main.path(forResource: "data_2020_11_29", ofType: "txt") {
                print("Switching to backup")
                completion(URL(fileURLWithPath: path))
            } else {
                // Very bad!
                print ("url error for backup!")
                completion(nil)
            }
        }
    }
    
    private static func download_latest_data(completion: @escaping () -> Void) {
        if let url = URL(string: "https://the-masked-manual.herokuapp.com/data_latest") {
            
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
