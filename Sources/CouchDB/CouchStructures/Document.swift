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

/// A protocol for a single JSON document the can be stored or retrieved from a CouchDB database.
/// http://docs.couchdb.org/en/stable/json-structure.html#couchdb-document
public protocol Document: Codable {

    /// Document ID
    var _id: String? { get }

    /// Revision ID
    var _rev: String? { get }
}
