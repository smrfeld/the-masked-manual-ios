//
/*
File: SearchModelViewController.swift
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

class SearchModelViewController: UIViewController {

    var search_term : String = ""
    var masks : [Mask] = []
    @IBOutlet weak var segmented_control: UISegmentedControl!
    
    @IBOutlet weak var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // After search
    var masks_filtered : [Mask] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sort
        masks.sort { (m1, m2) -> Bool in
            return m1.model < m2.model
        }
        
        masks_filtered = masks
        print(masks_filtered)

        // Setup search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search models"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // ***************
    // MARK: - Segment
    // ***************
    
    @IBAction func segmented_control_changed(_ sender: Any) {
        if segmented_control.selectedSegmentIndex == 0 {
            // Surgical masks only
            masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.is_surgical_mask() && (search_term == "" || mask.model.lowercased().contains(search_term.lowercased()))
            })
        } else if segmented_control.selectedSegmentIndex == 1 {
            // Both
            masks_filtered = masks.filter({ (mask) -> Bool in
                return search_term == "" || mask.model.lowercased().contains(search_term.lowercased())
            })
        } else {
            // Respirators only
            masks_filtered = masks.filter({ (mask) -> Bool in
                return !mask.is_surgical_mask() && (search_term == "" || mask.model.lowercased().contains(search_term.lowercased()))
            })
        }
        
        tableView.reloadData()
    }
    
    // ***************
    // MARK: - Filter search
    // ***************
    
    func filterContentForSearchText(_ searchText: String, company_name: String? = nil) {
        search_term = searchText
        
        if searchText == "" {
            masks_filtered = masks
        } else {
            masks_filtered = masks.filter({ (mask) -> Bool in
                return mask.model.lowercased().contains(searchText.lowercased())
            })
        }
        
        tableView.reloadData()
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


// ***************
// MARK: - Search
// ***************

extension SearchModelViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}

// ***************
// MARK: - Table
// ***************

extension SearchModelViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masks_filtered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maskTableViewCell") as! MaskTableViewCell
        cell.reload(mask: masks_filtered[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show
        let mask = masks_filtered[indexPath.row]
        
        let alert = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "maskDetailViewController") as! MaskDetailViewController
        alert.mask = mask
        alert.providesPresentationContextTransitionStyle = true
        alert.definesPresentationContext = true
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        alert.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(alert, animated: true, completion: nil)
        
        // performSegue(withIdentifier: "toMaskDetails", sender: mask)
    }
}
