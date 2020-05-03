//
//  CommitsTableViewController.swift
//  GithubCommits
//
//  Created by Tobi Kuyoro on 02/05/2020.
//  Copyright © 2020 Tobi Kuyoro. All rights reserved.
//

import UIKit
import CoreData

class CommitsTableViewController: UITableViewController {

    // MARK: - Properties

    var container: NSPersistentContainer!
    let url = URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100")!

    // MARK: - View Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        container = NSPersistentContainer(name: "Commits")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                NSLog("Error loading from persistent stores: \(error)")
            }
        }

        performSelector(inBackground: #selector(fetchCommits), with: nil)
    }

    // MARK: - Actions

    @objc func fetchCommits() {
        if let data = try? String(contentsOf: url) {
            let jsonCommits = JSON(parseJSON: data) // gives the data to SwiftyJSON to parse
            let jsonCommitsArray = jsonCommits.arrayValue // read the commits back out
            print("Received \(jsonCommitsArray.count) new commits.")

            DispatchQueue.main.async { [unowned self] in
                for jsonCommit in jsonCommitsArray {
                    let commit = Commit(context: self.container.viewContext)
                    self.configure(commit: commit, usingJSON: jsonCommit)
                }

                self.saveContext()
            }
        }
    }

    func configure(commit: Commit, usingJSON json: JSON) {
        commit.sha = json["sha"].stringValue
        commit.message = json["commit"]["message"].stringValue
        commit.url = json["url"].stringValue

        let formatter = ISO8601DateFormatter()
        let dateJSON = json["commit"]["committer"]["date"]
        commit.date = formatter.date(from: dateJSON.stringValue) ?? Date()
    }

    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                NSLog("An error occured while saving: \(error)")
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
