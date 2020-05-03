//
//  DetailViewController.swift
//  GithubCommits
//
//  Created by Tobi Kuyoro on 02/05/2020.
//  Copyright © 2020 Tobi Kuyoro. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailLabel: UILabel!

    var detailItem: Commit?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let detail = self.detailItem {
            detailLabel.text = detail.message
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Commit 1/\(detail.author.commits.count)",
//                                                                style: .plain, target: self,
//                                                                action: #selector(showAuthorCommits))
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
