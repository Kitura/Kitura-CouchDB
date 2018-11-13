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

/// A struct representing an item in the response JSON Array of Objects from an HTTP request to the _bulk_docs API.  
/// http://docs.couchdb.org/en/stable/api/database/bulk-api.html#post--db-_bulk_docs
public struct BulkResponse: Codable {
    /// A Bool representing whether the document was successfully processed
    public let ok: Bool?

    /// The Document ID.
    public let id: String

    /// New document revision token. Available if document has saved without errors.
    public let rev: String?

    /// Error type.
    public let error: String?

    /// Error reason.
    public let reason: String?
}
