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
    /// Retrieve a session cookie from the database by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func getSessionCookie(name: String, password: String, callback: (String?, JSON?, NSError?) -> ()) {

        let requestOptions = userDatabase.prepareRequest(connectionProperties,
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

                cookie = sessionResponse?.headers["Set-Cookie"]
            }
            else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
            }
            callback(cookie, document, error)
        }
        req.end(body)
    }
}
