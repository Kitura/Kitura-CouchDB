/**
 * Copyright IBM Corporation 2019
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// A struct representing an array of JSON documents.
/// This is used for adding or updating multiple documents at once using the bulk api.  
/// http://docs.couchdb.org/en/stable/api/database/bulk-api.html#db-bulk-docs
public struct BulkDocuments {

    /// If false, prevents the database from assigning documents new revision IDs
    /// If new_edits is nil, CouchDB defaults to true.
    public let new_edits: Bool?

    /// An array of JSON `Document` objects.
    public var docs: [[String: Any]]

    /// Initialize a `BulkDocuments` instance.
    ///
    /// - parameter docs: An array of JSON `Document` objects.
    /// - parameter new_edits: A Bool to set whether CouchDB assigns documents new revision IDs.
    public init(docs: [[String: Any]], new_edits: Bool? = nil) {
        self.docs = docs
        self.new_edits = new_edits
    }
}
