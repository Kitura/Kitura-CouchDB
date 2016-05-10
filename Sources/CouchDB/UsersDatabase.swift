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

    #if os(Linux)
    typealias JSONDictionary = [String: Any]
    #else
    typealias JSONDictionary = [String: AnyObject]
    #endif

    ///
    /// Create new user by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func createUser(document: JSON, callback: (id: String?, document: JSON?, error: NSError?) -> ()) {
        if let requestBody = document.rawString(), name = document["name"].string {
            let id = "org.couchdb.user:\(name)"
            var doc: JSON?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                             method: "PUT",
                                                             path: "/_users/\(id)",
                                                             hasBody: true,
                                                             contentType: "application/json")
            let req = Http.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsJson(response)
                    if response.statusCode != HttpStatusCode.CREATED && response.statusCode != HttpStatusCode.ACCEPTED {
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: id, rev: nil)
                    }
                }
                else {
                    error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
                }
                callback(id: id, document: doc, error: error)
            }
            req.end(requestBody)
        }
        else {
            callback(id: nil,
                     document: nil,
                     error: CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
        }
    }

    ///
    /// Fetch a user by name
    ///
    /// - Parameter name: String of username
    /// - Parameter callback: callback function with the user inside the document's JSON
    ///
    public func getUser(name: String, callback: (document: JSON?, error: NSError?) -> ()) {
        let id = "org.couchdb.user:\(name)"
        retrieve(id, callback: { (doc, error) in
            var json = JSONDictionary()
            if let document = doc where error == nil {
                json["user"] = document.object
            }
            callback(document: JSON(json), error: error)
        })
    }
}
