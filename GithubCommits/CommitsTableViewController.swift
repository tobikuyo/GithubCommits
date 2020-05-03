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

    let url = URL(string: "https://api.github.com/repos/apple/swift/commits?per_page=100")!
    var container: NSPersistentContainer!
    var commits = [Commit]()

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

        loadSavedData()
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
                self.loadSavedData()
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

    func loadSavedData() {
        let request = Commit.createFetchRequest()
        let sortByDate = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortByDate]

        do {
            commits = try container.viewContext.fetch(request)
            print("Got \(commits.count) commits")
            tableView.reloadData()
        } catch {
            NSLog("Error fetching Commit object: \(error)")
        }
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commits.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommitCell", for: indexPath)

        let commit = commits[indexPath.row]
        cell.textLabel?.text = commit.message
        cell.detailTextLabel?.text = commit.date.description

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
