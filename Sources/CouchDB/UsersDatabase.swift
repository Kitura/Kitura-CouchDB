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

    ///
    /// Create new user by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func signupUser(document: JSON,
                           callback: (id: String?, document: JSON?, error: NSError?) -> ()) {
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
            print(requestBody)
            req.end(requestBody)
        }
        else {
            callback(id: nil,
                     document: nil,
                     error: CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
        }
    }

    ///
    /// Retrieve a session cookie from the database by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func getSessionCookie(name: String, password: String, callback: (String?, JSON?, NSError?) -> ()) {

        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "POST",
                                                         path: "/_session",
                                                         hasBody: true,
                                                         contentType: "application/x-www-form-urlencoded")
        let body = "name=\(name)&password=\(password)"
        let id = "org.couchdb.user:\(name)"

        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            var cookie: String?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HttpStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: id, rev: nil)
                }

                cookie = response.headers["Set-Cookie"]
            }
            else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
            }
            callback(cookie, document, error)
        }
        req.end(body)
    }
}
