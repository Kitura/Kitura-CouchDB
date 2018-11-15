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

// MARK: CouchDBClient

/// Represents a CouchDB connection.
public class CouchDBClient {

    // MARK: Properties
    
    /// Connection properties for the `CouchDBClient`.
    public let connProperties: ConnectionProperties

    // MARK: Initializer
    
    /// Initialize a `CouchDBClient`.
    ///
    /// - parameter connectionProperties: The connection properties for the CouchDB connection.
    public init(connectionProperties: ConnectionProperties) {
        self.connProperties = connectionProperties
    }

    // MARK: Databases
    
    /// Returns a `Database` instance by name.
    ///
    /// - parameter dbName: String name of the desired `Database`.
    public func database(_ dbName: String) -> Database {
        return Database(connProperties: self.connProperties, dbName: dbName)
    }

    /// Returns a `UsersDatabase` instance.
    public func usersDatabase() -> UsersDatabase {
        return UsersDatabase(connProperties: self.connProperties, dbName: "_users")
    }

    /// Create a new `Database`.
    ///
    /// - parameters:
    ///     - dbName: String name of the database
    ///     - callback: Callback containing the newly created `Database`, or an `CouchDBError` on failure.
    public func createDB(_ dbName: String, callback: @escaping (Database?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                if response.statusCode == .created {
                    return callback(Database(connProperties: self.connProperties, dbName: dbName), nil)
                } else {
                    return callback(nil, CouchDBUtils.getBodyAsError(response))
                }
            } else {
                return callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: "No response from createDB request"))
            }
        }
        req.end()
    }

    /// Returns a Bool indicating whether a `Database` with the given name exists.
    ///
    /// - parameters:
    ///     - dbName: String name of the `Database` to look up.
    ///     - callback: Callback containing the result of the lookup or an CouchDBError if one occurred.
    public func dbExists(_ dbName: String, callback: @escaping (Bool) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response, response.statusCode == HTTPStatusCode.OK {
                return callback(true)
            } else {
                return callback(false)
            }
        }
        req.end()
    }

    /// Delete a `Database` given a local instance of it.
    ///
    /// - parameters:
    ///     - database: An instance of the `Database` to delete.
    ///     - callback: Callback containing an CouchDBError if one occurred.
    public func deleteDB(_ database: Database, callback: @escaping (CouchDBError?) -> ()) {
        deleteDB(database.name, callback: callback)
    }

    /// Delete a `Database` given its name.
    ///
    /// - parameters:
    ///     - dbName: String name of the `Database` to delete.
    ///     - callback: Callback containing an CouchDBError if one occurred.
    public func deleteDB(_ dbName: String, callback: @escaping (CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        CouchDBUtils.deleteRequest(options: requestOptions, callback: callback)
    }

    // MARK: UUID
    
    /// Returns some UUIDs created by CouchDB.
    ///
    /// - parameters:
    ///     - count: The number of UUIDs to get.
    ///     - callback: Callback containing an array of UUIDs or an CouchDBError if one occured.
    public func getUUIDs(count : UInt, callback : @escaping ([String]?, CouchDBError?) -> Void) {

        let url = "/_uuids?count=\(count)"

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: url, hasBody: false)
        CouchDBUtils.couchRequest(options: requestOptions, passStatusCodes: [.OK]) { (uuids: [String: [String]]?, error) in
            callback(uuids?["uuids"], nil)
        }
    }

    /// Returns a UUID created by CouchDB.
    ///
    /// - parameter callback: Callback containing the UUID or an CouchDBError if one occurred.
    public func getUUID(callback : @escaping (String?, CouchDBError?) -> Void) {
        getUUIDs(count: 1) { (uuids, error) in
            var uuid : String?
            if let uuids = uuids,
                uuids.count > 0 {
                uuid = uuids.first
            }
            callback(uuid, error)
        }
    }

    // MARK: Config
    
    /// Set a CouchDB configuration parameter to a new value.
    ///
    /// http://docs.couchdb.org/en/stable/api/server/configuration.html#put--_node-node-name-_config-section-key
    /// - parameters:
    ///     - node: The server node that will be configured.
    ///     - section: The configuration section to be changed.
    ///     - key: The key from the configuration section to be changed.
    ///     - callback: Callback containing an CouchDBError if one occurred.
    public func setConfig(node: String = "_local", section: String, key: String, value: String, callback: @escaping (CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "PUT",
                                                         path: "/_node/\(node)/_config/\(section)/\(key)",
                                                         hasBody: true,
                                                         contentType: "application/json")
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                if response.statusCode == .OK {
                    return callback(nil)
                } else {
                    return callback(CouchDBUtils.getBodyAsError(response))
                }
            }
            return callback(CouchDBError(HTTPStatusCode.internalServerError, reason: "No response from setConfig request"))
        }
        let jsonValue = "\"" + value + "\""
        req.end(jsonValue)
    }

    /// Get the entire configuration document for a server node.
    ///
    /// http://docs.couchdb.org/en/stable/api/server/configuration.html#node-node-name-config
    /// - parameters:
    ///     - node: The server node with the configuration document.
    ///     - callback: Callback containing either the configuration dictionary or an CouchDBError if one occurred.
    public func getConfig(node: String = "_local", callback: @escaping ([String: [String: String]]?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "GET",
                                                         path: "/_node/\(node)/_config/",
                                                         hasBody: false)
        CouchDBUtils.couchRequest(options: requestOptions, passStatusCodes: [.OK], callback: callback)
    }
    
    /// Get the configuration dictionary for a section of the configuration document.
    ///
    /// http://docs.couchdb.org/en/stable/api/server/configuration.html#node-node-name-config-section
    /// - parameters:
    ///     - node: The server node with the configuration document.
    ///     - section: The configuration section to be retrieved.
    ///     - callback: Callback containing either the configuration section dictionary or an CouchDBError if one occurred.
    public func getConfig(node: String = "_local", section: String, callback: @escaping ([String: String]?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "GET",
                                                         path: "/_node/\(node)/_config/\(section)",
                                                         hasBody: false)
        CouchDBUtils.couchRequest(options: requestOptions, passStatusCodes: [.OK], callback: callback)
    }
    
    /// Get the value for a specific key in the configuration document.
    /// The returned value will be a JSON String.
    /// http://docs.couchdb.org/en/stable/api/server/configuration.html#node-node-name-config-section
    /// - parameters:
    ///     - node: The server node with the configuration document.
    ///     - section: The configuration section to be retrieved.
    ///     - key: The key in the configuration section for the desired value.
    ///     - callback: Callback containing either the configuration value as a JSON String or an CouchDBError.
    public func getConfig(node: String = "_local", section: String, key: String, callback: @escaping (String?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "GET",
                                                         path: "/_node/\(node)/_config/\(section)/\(key)",
                                                         hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                // JSONSerialization used here since JSONEncoder will not decode fragments
                if let configJSON = CouchDBUtils.getBodyAsData(response),
                    let jsonString = try? (JSONSerialization.jsonObject(with: configJSON, options: [.allowFragments]) as? String)
                {
                    return callback(jsonString, nil)
                } else {
                    return callback(nil, CouchDBUtils.getBodyAsError(response))
                }
            } else {
                return callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: "No response from getConfig request"))
            }
        }
        req.end()
    }

    // MARK: Sessions
    
    /// Create a new session for the given user credentials.
    ///
    /// - parameters:
    ///     - name: Username String.
    ///     - password: Password String.
    ///     - callback: Callback containing either the session cookie and a `NewSessionResponse`, or an CouchDBError.
    public func createSession(name: String, password: String, callback: @escaping (String?, NewSessionResponse?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties,
                                                         method: "POST",
                                                         path: "/_session",
                                                         hasBody: true,
                                                         contentType: "application/x-www-form-urlencoded")
        let body = "name=\(name)&password=\(password)"
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                
                if response.statusCode != HTTPStatusCode.OK {
                    return callback(nil, nil, CouchDBUtils.getBodyAsError(response))
                }
                do {
                    let cookie = response.headers["Set-Cookie"]?.first
                    let newSessionResponse: NewSessionResponse = try CouchDBUtils.getBodyAsCodable(response)
                    return callback(cookie, newSessionResponse, nil)
                } catch {
                    return callback(nil, nil, CouchDBError(response.httpStatusCode, reason: error.localizedDescription))
                }
            } else {
                return callback(nil, nil, CouchDBError(HTTPStatusCode.internalServerError, reason: "No response from createSession request"))
            }
        }
        req.end(body)
    }

    /// Verify a session cookie.
    ///
    /// - parameters:
    ///     - cookie: String session cookie.
    ///     - callback: Callback containing either the `UserSessionInformation` or an CouchDBError if the cookie is not valid.
    public func getSession(cookie: String, callback: @escaping (UserSessionInformation?, CouchDBError?) -> ()) {
        var requestOptions: [ClientRequest.Options] = []
        requestOptions.append(.hostname(connProperties.host))
        requestOptions.append(.port(Int16(connProperties.port)))
        requestOptions.append(.method("GET"))
        requestOptions.append(.path("/_session"))

        var headers = [String : String]()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        headers["Cookie"] = cookie
        requestOptions.append(.headers(headers))
        CouchDBUtils.couchRequest(options: requestOptions, passStatusCodes: [.OK], callback: callback)
    }
}
