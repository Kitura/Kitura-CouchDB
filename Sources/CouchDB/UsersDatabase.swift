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

    /// Create new user by name and password.
    ///
    /// - parameters:
    ///     - name: Username String.
    ///     - password: Password String.
    ///     - callback: Callback containing the DocumentResponse,
    ///                 or an NSError if one occurred.
    public func createUser<U: NewUserDocument>(document: U, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let id = "org.couchdb.user:\(document.name)"
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "PUT",
                                                         path: "/_users/\(id)",
                                                         hasBody: true,
                                                         contentType: "application/json")
        CouchDBUtils.documentRequest(document: document, options: requestOptions) { (response, error) in
            callback(response, error)
        }
    }

    /// Get a user by name.
    ///
    /// - parameters:
    ///     - name: Name String of the desired user.
    ///     - callback: Callback containing the user JSON, or an NSError if one occurred.
    public func getUser<U: RetrievedUserDocument>(name: String, callback: @escaping (U?, NSError?) -> ()) {
        let id = "org.couchdb.user:\(name)"
        retrieve(id, callback: { (doc, error) in
            callback(doc, error)
        })
    }
}


