/**
 * Copyright IBM Corporation 2016, 2017
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

// MARK: Users Database

/// Represents a CouchDB database of users.
public class UsersDatabase: Database {

    typealias JSONDictionary = [String: Any]

    /// Create new user by name and password.
    ///
    /// - parameters:
    ///     - name: Username String.
    ///     - password: Password String.
    ///     - callback: Callback containing the username, JSON response,
    ///                 and an NSError if one occurred.
    public func createUser(document: CouchUser, callback: @escaping (CouchResponse?, NSError?) -> ()) {
        if let requestBody = try? JSONEncoder().encode(document) {
            let id = "org.couchdb.user:\(document.name)"
            var doc: CouchResponse?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                             method: "PUT",
                                                             path: "/_users/\(id)",
                                                             hasBody: true,
                                                             contentType: "application/json")
            let req = HTTP.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsCodable(response)
                    if response.statusCode != HTTPStatusCode.created && response.statusCode != HTTPStatusCode.accepted {
                        let errorDesc: CouchErrorResponse? = CouchDBUtils.getBodyAsCodable(response)
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: errorDesc, id: id, rev: nil)
                    }
                } else {
                    error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
                }
                callback(doc, error)
            }
            req.end(requestBody)
        } else {
            callback(nil, CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
        }
    }

    /// Get a user by name.
    ///
    /// - parameters:
    ///     - name: Name String of the desired user.
    ///     - callback: Callback containing the user JSON, or an NSError if one occurred.
    public func getUser(name: String, callback: @escaping (UserContextObject?, NSError?) -> ()) {
        let id = "org.couchdb.user:\(name)"
        retrieve(id, callback: { (doc, error) in
            callback(doc, error)
        })
    }
}


