//
/*
 File: SearchViewController.swift
 Created by: Oliver K. Ernst
 Date: 11/22/20
 
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
import Eureka

class SearchCompanyViewController : UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var masks : [Mask] = []
    var companies : [Company] = []
    
    // After search
    var companies_filtered : [Company] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        // Load masks
        masks = load_masks()
        for mask in masks {
            print(mask)
        }
        companies = organize_masks_by_company(masks)
        companies.sort { (c1, c2) -> Bool in
            return c1.name < c2.name
        }
        companies_filtered = companies
        
        // Setup search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search companies"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // White text for search
        searchController.searchBar.compatibleSearchTextField.textColor = UIColor.white

        // Show by default, do not hide when scrolling
        searchController.searchBar.becomeFirstResponder()
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    // ***************
    // MARK: - Load masks
    // ***************
    
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
    
    // ***************
    // MARK: - Filter search
    // ***************
    
    func filterContentForSearchText(_ searchText: String, company_name: String? = nil) {
        if searchText == "" {
            companies_filtered = companies
        } else {
            companies_filtered = companies.filter({ (company) -> Bool in
                return company.name.lowercased().contains(searchText.lowercased())
            })
        }
        
        tableView.reloadData()
    }
    
    // ***************
    // MARK: - Navigation
    // ***************
    
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSearchModels", let vc = segue.destination as? SearchModelViewController, let company = sender as? Company {
            vc.masks = company.masks
        }
     }
    
}

// ***************
// MARK: - Search
// ***************

extension SearchCompanyViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}

// ***************
// MARK: - Table
// ***************

extension SearchCompanyViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return companies_filtered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "companyTableViewCell") as! CompanyTableViewCell
        cell.reload(company: companies_filtered[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Segue
        let company = companies_filtered[indexPath.row]
        performSegue(withIdentifier: "toSearchModels", sender: company)
    }
}
