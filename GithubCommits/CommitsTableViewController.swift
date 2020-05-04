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
    var commitPredicate: NSPredicate?

    // MARK: - View Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        container = NSPersistentContainer(name: "Commits")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error {
                NSLog("Error loading from persistent stores: \(error)")
            }
        }

        performSelector(inBackground: #selector(fetchCommits), with: nil)

        loadSavedData()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(changeFilter))
    }

    // MARK: - Actions

    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                NSLog("An error occured while saving: \(error)")
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

        /// This is the Author entity that has a relationship to the Commit entity
        var commitAuthor: Author!

        let authorRequest = Author.createFetchRequest()
        let authorName = json["commit"]["committer"]["name"]
        authorRequest.predicate = NSPredicate(format: "name == %@", authorName.stringValue)

        if let authors = try? container.viewContext.fetch(authorRequest) {
            if authors.count > 0 {
                commitAuthor = authors[0]
            }
        }

        if commitAuthor == nil {
            let author = Author(context: container.viewContext)
            let name = json["commit"]["committer"]["name"].stringValue
            let email = json["commit"]["committer"]["email"].stringValue

            author.name = name
            author.email = email
            commitAuthor = author
        }

        commit.author = commitAuthor
    }

    func loadSavedData() {
        let request = Commit.createFetchRequest()
        let sortByDate = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortByDate]
        request.predicate = commitPredicate

        do {
            commits = try container.viewContext.fetch(request)
            print("Got \(commits.count) commits")
            tableView.reloadData()
        } catch {
            NSLog("Error fetching Commit object: \(error)")
        }
    }

    func getNewestCommitDate() -> String {
        let formatter = ISO8601DateFormatter()

        let newest = Commit.createFetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        newest.sortDescriptors = [sort]
        newest.fetchLimit = 1

        if let commits = try? container.viewContext.fetch(newest) {
            if commits.count > 0 {
                return formatter.string(from: commits[0].date.addingTimeInterval(1))
            }
        }

        return formatter.string(from: Date(timeIntervalSince1970: 0))
    }

    @objc func fetchCommits() {
        let newCommitDate = getNewestCommitDate()

        if let data = try? String(contentsOf: URL(string: "\(url)&since=\(newCommitDate)")!) {
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

    @objc func changeFilter() {
        let alert = UIAlertController(title: "Filter Commits", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Show Only Fixes", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "message CONTAINS[c] 'fix'")
            self.loadSavedData()
        }))

        alert.addAction(UIAlertAction(title: "Ignore Pull Requests", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "NOT message BEGINSWITH 'Merge pull request'")
            self.loadSavedData()
        }))

        alert.addAction(UIAlertAction(title: "Show Only Recent", style: .default, handler: { [unowned self] _ in
            let twelveHoursAgo = Date().addingTimeInterval(-43_200)
            self.commitPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as NSDate)
            self.loadSavedData()
        }))

        alert.addAction(UIAlertAction(title: "Show only Durian commits", style: .default) { [unowned self] _ in
            self.commitPredicate = NSPredicate(format: "author.name == 'Joe Groff'")
            self.loadSavedData()
        })

        alert.addAction(UIAlertAction(title: "Show All Commits", style: .default, handler: { [unowned self] _ in
            self.commitPredicate = nil
            self.loadSavedData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
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
        let author = commit.author.name
        let date = commit.date.description
        cell.textLabel?.text = commit.message
        cell.detailTextLabel?.text = "By \(author) on \(date)"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            vc.detailItem = commits[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let commit = commits[indexPath.row]
            container.viewContext.delete(commit)
            commits.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveContext()
        }
    }
}
