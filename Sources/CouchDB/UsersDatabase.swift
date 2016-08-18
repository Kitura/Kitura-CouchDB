/**
 * Copyright IBM Corporation 2016
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
import SwiftyJSON
import KituraNet

// MARK: Users Database

public class UsersDatabase : Database {

    typealias JSONDictionary = [String: Any]

    ///
    /// Create new user by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func createUser(document: JSON, callback: @escaping (String?, JSON?, NSError?) -> ()) {
        if let requestBody = document.rawString(), let name = document["name"].string {
            let id = "org.couchdb.user:\(name)"
            var doc: JSON?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                             method: "PUT",
                                                             path: "/_users/\(id)",
                                                             hasBody: true,
                                                             contentType: "application/json")
            let req = HTTP.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsJson(response)
                    if response.statusCode != HTTPStatusCode.created && response.statusCode != HTTPStatusCode.accepted {
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: id, rev: nil)
                    }
                }
                else {
                    error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
                }
                callback(id, doc, error)
            }
            req.end(requestBody)
        }
        else {
            callback(nil,
                     nil,
                     CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
        }
    }

    ///
    /// Fetch a user by name
    ///
    /// - Parameter name: String of username
    /// - Parameter callback: callback function with the user inside the document's JSON
    ///
    public func getUser(name: String, callback: @escaping (JSON?, NSError?) -> ()) {
        let id = "org.couchdb.user:\(name)"
        retrieve(id, callback: { (doc, error) in
            var json = JSONDictionary()
            if let document = doc, error == nil {
                json["user"] = document.object
            }
#if os(Linux)
            callback(document: JSON(json), error: error)
#else
            callback(JSON(json as AnyObject), error)
#endif
        })
    }
}
