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

// MARK: CouchDBClient

#if os(OSX)
    public typealias CouchDBValue = AnyObject
#else
    public typealias CouchDBValue = Any
#endif

///
/// CouchDB _session callback
///
public typealias SessionCallback = (cookie: String?, document: JSON?, error: NSError?) -> ()

public class CouchDBClient {

    ///
    /// Connection properties
    ///
    public let connProperties: ConnectionProperties

    ///
    /// Initializes a CouchDB connection
    ///
    /// - Returns: a new CouchDBClient instance
    public init(connectionProperties: ConnectionProperties) {
        self.connProperties = connectionProperties
    }

    ///
    /// Returns a Database instance by name
    ///
    /// - Parameter dbName: String for the database name
    /// - Returns: a database instance matching the name
    ///
    public func database(_ dbName: String) -> Database {
        return Database(connProperties: self.connProperties, dbName: dbName)
    }

    ///
    /// Returns a UsersDatabase instance
    ///
    /// - Returns: a database instance matching the name
    ///
    public func usersDatabase() -> UsersDatabase {
        return UsersDatabase(connProperties: self.connProperties, dbName: "_users")
    }

    ///
    /// Create a new database
    ///
    /// - Parameter dbName: String for the name of the database
    /// - Parameter callback: a function containing the Database instance
    ///
    public func createDB(_ dbName: String, callback: (Database?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT",
                                                         path: "/\(Http.escapeUrl(dbName))", hasBody: false)
        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var db: Database?
            if let response = response {
                if response.statusCode == HttpStatusCode.CREATED {
                    db = Database(connProperties: self.connProperties, dbName: dbName)
                } else {
                    if let descOpt = try? response.readString(), let desc = descOpt {
                        error = CouchDBUtils.createError(response.statusCode,
                                                         errorDesc: JSON.parse(string: desc), id: nil, rev: nil)
                    } else {
                        error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                    }
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(db, error)
        }
        req.end()
    }

    ///
    /// Checks if a database with a name exists already
    ///
    /// - Parameter dbName: String for the name of the database
    /// - Parameter callback: a function containing a boolean that is true if the database exists
    ///
    public func dbExists(_ dbName: String, callback: (Bool, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(Http.escapeUrl(dbName))", hasBody: false)
        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var exists = false
            if let response = response {
                if response.statusCode == HttpStatusCode.OK {
                    exists = true
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(exists, error)
        }
        req.end()
    }

    ///
    /// Delete a database by instance
    ///
    /// - Parameter db: instance of Database to delete
    /// - Parameter callback: a function that contains an NSerror? if a problem occurred
    ///
    public func deleteDB(_ database: Database, callback: (NSError?) -> ()) {
        deleteDB(database.name, callback: callback)
    }

    ///
    /// Delete a database by name
    ///
    /// - Parameter dbName: a String for the name of the database
    /// - Parameter callback: a function containing an NSError? if a problem occurred
    ///
    public func deleteDB(_ dbName: String, callback: (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE",
                                                         path: "/\(Http.escapeUrl(dbName))", hasBody: false)
        let req = Http.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if response.statusCode != HttpStatusCode.OK {
                    if let descOpt = try? response.readString(), let desc = descOpt {
                        error = CouchDBUtils.createError(response.statusCode,
                                                         errorDesc: JSON.parse(string: desc), id: nil, rev: nil)
                    } else {
                        error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                    }
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(error)
        }
        req.end()
    }

    ///
    /// Configure CouchDB
    ///
    /// - Parameter keyPath: String key path to the parameter
    /// - Parameter value: Value to set
    /// - Parameter callback: Success of operation
    ///

    public func setConfig(keyPath: String, value: CouchDBValue, callback: (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "PUT",
                                                         path: "/_config/\(keyPath)",
                                                         hasBody: true,
                                                         contentType: "application/json")
        let req = Http.request(requestOptions) { response in
            var configError: NSError?
            if let response = response {
                if response.statusCode != .OK {
                    configError = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            }
            callback(configError)
        }
        let body = JSON("\"\(value)\"")

        if let body = body.rawString() {
            req.end(body)
        }
        else {
            req.end()
        }
    }

    ///
    /// Get CouchDB Configuration
    ///
    /// - Parameter callback: Response body of /_config/keyPath
    ///

    public func getConfig(keyPath: String, callback: (JSON?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "GET",
                                                         path: "/_config/\(keyPath)",
                                                         hasBody: false,
                                                         contentType: "application/json")
        let req = Http.request(requestOptions) { response in
            var configError: NSError?
            var configJSON: JSON?
            if let response = response {
                do {
                    let body = try response.readString()
                    if let body = body {
                        configJSON = JSON(body)
                    }
                } catch {
                    configError = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            }
            callback(configJSON, configError)
        }

        req.end()
    }

    ///
    /// Retrieve a session cookie from the database by name and password
    ///
    /// - Parameter name: String of username
    /// - Parameter password: String of password
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func createSession(name: String, password: String, callback: SessionCallback) {

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
            callback(cookie: cookie, document: document, error: error)
        }
        req.end(body)
    }

    ///
    /// Verify a session cookie
    ///
    /// - Parameter cookie: String of cookie
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func getSession(cookie: String, callback: SessionCallback) {

        var requestOptions = [ClientRequestOptions]()
        requestOptions.append(.Hostname(connProperties.host))
        requestOptions.append(.Port(connProperties.port))
        requestOptions.append(.Method("GET"))
        requestOptions.append(.Path("/_session"))

        var headers = [String : String]()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        headers["Cookie"] = cookie
        requestOptions.append(.Headers(headers))

        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HttpStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }
            }
            else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(cookie: cookie, document: document, error: error)
        }
        req.end()
    }

    ///
    /// Logout a session
    ///
    /// - Parameter cookie: String of cookie
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func deleteSession(cookie: String, callback: SessionCallback) {

        var requestOptions = [ClientRequestOptions]()
        requestOptions.append(.Hostname(connProperties.host))
        requestOptions.append(.Port(connProperties.port))
        requestOptions.append(.Method("DELETE"))
        requestOptions.append(.Path("/_session"))

        var headers = [String : String]()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        headers["Cookie"] = cookie
        requestOptions.append(.Headers(headers))

        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            var cookie: String?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HttpStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }

                cookie = response.headers["Set-Cookie"]
            }
            else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(cookie: cookie, document: document, error: error)
        }
        req.end()
    }
}
