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
import KituraNet

/// A struct representing the JSON response from CouchDB when an error occurs.  
/// http://docs.couchdb.org/en/stable/json-structure.html#couchdb-error-status
public struct CouchDBError: Codable, Swift.Error, CustomStringConvertible {
    
    /// Return a human readable description of the error.
    public var description: String {
        var errorDescription = "Error: \(error), \(reason)"
        if let id = id {
            errorDescription += ", while processing: \(id)"
        }
        return errorDescription
    }

    /// The Document ID.
    public let id: String?

    /// The error that occurred.
    public let error: String
    
    /// The HTTP status code of the error
    public internal(set) var statusCode: Int = HTTPStatusCode.unknown.rawValue

    /// Error reason.
    public let reason: String
    
    init(_ code: HTTPStatusCode, id: String? = nil, reason: String? = nil) {
        self.init(code.rawValue, id: id, reason: reason)
    }
    
    init(_ code: Int, id: String? = nil, reason: String? = nil) {
        self.statusCode = code
        self.id = id
        let error = HTTP.statusCodes[code] ?? String(code)
        self.error = error
        self.reason = reason ?? error
    }
    
    // Don't decode statusCode because it is extracted from the HTTP request.
    enum CodingKeys: String, CodingKey {
        case error, reason, id
    }
}
