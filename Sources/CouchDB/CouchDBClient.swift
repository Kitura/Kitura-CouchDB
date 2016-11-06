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
public typealias SessionCallback = (String?, JSON?, NSError?) -> ()

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
    public func createDB(_ dbName: String, callback: @escaping (Database?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var db: Database?
            if let response = response {
                if response.statusCode == .created {
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
    public func dbExists(_ dbName: String, callback: @escaping (Bool, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var exists = false
            if let response = response {
                if response.statusCode == HTTPStatusCode.OK {
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
    public func deleteDB(_ database: Database, callback: @escaping (NSError?) -> ()) {
        deleteDB(database.name, callback: callback)
    }

    ///
    /// Delete a database by name
    ///
    /// - Parameter dbName: a String for the name of the database
    /// - Parameter callback: a function containing an NSError? if a problem occurred
    ///
    public func deleteDB(_ dbName: String, callback: @escaping (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if response.statusCode != HTTPStatusCode.OK {
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

    public func getUUIDs(count : UInt, callback : @escaping ([String]?, NSError?) -> Void) {

        let url = "/_uuids?count=\(count)"

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: url, hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var uuids: [String]?
            if let response = response {
                if response.statusCode == HTTPStatusCode.OK {

                    var data = Data()
                    do {
                        try response.readAllData(into: &data)

                        let responseJSON = JSON(data: data)

                        let uuidsJSON = responseJSON["uuids"]

                        uuids = uuidsJSON.array?.flatMap({ (uuidJSON) -> String? in
                            return uuidJSON.string
                        })

                    } catch let caughtError as NSError {
                        error = caughtError
                    }
                } else {
                    error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(uuids, error)
        }
        req.end()
    }

    public func getUUID(callback : @escaping (String?, NSError?) -> Void) {

        self.getUUIDs(count: 1) { (uuids, error) in

            var uuid : String?
            if let uuids = uuids,
                uuids.count > 0 {
                uuid = uuids.first
            }

            callback(uuid, error)
        }
    }


    ///
    /// Configure CouchDB
    ///
    /// - Parameter keyPath: String key path to the parameter
    /// - Parameter value: Value to set
    /// - Parameter callback: Success of operation
    ///

    public func setConfig(keyPath: String, value: CouchDBValue, callback: @escaping (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "PUT",
                                                         path: "/_config/\(keyPath)",
                                                         hasBody: true,
                                                         contentType: "application/json")
        let req = HTTP.request(requestOptions) { response in
            var configError: NSError?
            if let response = response {
                if response.statusCode != .OK {
                    configError = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            }
            callback(configError)
        }
#if os(Linux)
        let body = JSON("\"\(value)\"")
#else
            let body = JSON("\"\(value)\"" as NSString)
#endif

        if let body = body.rawString() {
            req.end(body)
        } else {
            req.end()
        }
    }

    ///
    /// Get CouchDB Configuration
    ///
    /// - Parameter callback: Response body of /_config/keyPath
    ///

    public func getConfig(keyPath: String, callback: @escaping (JSON?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "GET",
                                                         path: "/_config/\(keyPath)",
                                                         hasBody: false,
                                                         contentType: "application/json")
        let req = HTTP.request(requestOptions) { response in
            var configError: NSError?
            var configJSON: JSON?
            if let response = response {
                do {
                    let body = try response.readString()
                    if let body = body {
#if os(Linux)
                        configJSON = JSON(body)
#else
                        configJSON = JSON(body as NSString)
#endif
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
    public func createSession(name: String, password: String, callback: @escaping SessionCallback) {

        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "POST",
                                                         path: "/_session",
                                                         hasBody: true,
                                                         contentType: "application/x-www-form-urlencoded")
        let body = "name=\(name)&password=\(password)"
        let id = "org.couchdb.user:\(name)"

        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            var cookie: String?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: id, rev: nil)
                }

                cookie = response.headers["Set-Cookie"]?.first
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
            }
            callback(cookie, document, error)
        }
        req.end(body)
    }

    ///
    /// Verify a session cookie
    ///
    /// - Parameter cookie: String of cookie
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func getSession(cookie: String, callback: @escaping SessionCallback) {

        var requestOptions: [ClientRequest.Options] = []
        requestOptions.append(.hostname(connProperties.host))
        requestOptions.append(.port(connProperties.port))
        requestOptions.append(.method("GET"))
        requestOptions.append(.path("/_session"))

        var headers = [String : String]()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        headers["Cookie"] = cookie
        requestOptions.append(.headers(headers))

        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(cookie, document, error)
        }
        req.end()
    }

    ///
    /// Logout a session
    ///
    /// - Parameter cookie: String of cookie
    /// - Parameter callback: callback function with the cookie and document's JSON
    ///
    public func deleteSession(cookie: String, callback: @escaping SessionCallback) {

        var requestOptions: [ClientRequest.Options] = []
        requestOptions.append(.hostname(connProperties.host))
        requestOptions.append(.port(connProperties.port))
        requestOptions.append(.method("DELETE"))
        requestOptions.append(.path("/_session"))

        var headers = [String : String]()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        headers["Cookie"] = cookie
        requestOptions.append(.headers(headers))

        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var document: JSON?
            var cookie: String?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)

                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }

                cookie = response.headers["Set-Cookie"]?.first
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(cookie, document, error)
        }
        req.end()
    }
}
