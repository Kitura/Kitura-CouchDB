/**
 * Copyright IBM Corporation 2018
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

/// A struct representing the JSON returned when querying a Database or View.  
/// http://docs.couchdb.org/en/stable/json-structure.html#all-database-documents
public struct AllDatabaseDocuments {
    init(total_rows: Int, offset: Int, rows: [[String: Any]], update_seq: String? = nil) {
        self.total_rows = total_rows
        self.offset = offset
        self.rows = rows
        self.update_seq = update_seq
    }

    /// Number of documents in the database/view.
    public let total_rows: Int?

    /// Offset where the document list started
    public let offset: Int?

    /// Current update sequence for the database.
    public let update_seq: String?

    /// Array of JSON `Document` objects.
    public let rows: [[String: Any]]
}
