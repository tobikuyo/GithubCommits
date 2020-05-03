//
//  Commit+CoreDataProperties.swift
//  GithubCommits
//
//  Created by Tobi Kuyoro on 03/05/2020.
//  Copyright © 2020 Tobi Kuyoro. All rights reserved.
//
//

import Foundation
import CoreData


extension Commit {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Commit> {
        return NSFetchRequest<Commit>(entityName: "Commit")
    }

    @NSManaged public var date: Date
    @NSManaged public var message: String
    @NSManaged public var sha: String
    @NSManaged public var url: String
    @NSManaged public var author: Author

}
