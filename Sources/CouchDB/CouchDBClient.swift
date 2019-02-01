/**
 * Copyright IBM Corporation 2019
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

/**
 The `CouchDBClient` represents a connection to a CouchDB server. It is initialized with your `ConnectionProperties` and handles the creation, retrieval and deletion of CouchDB databases.
 ### Usage Example: ###
 ```swift
 let conProperties = ConnectionProperties(
     host: "127.0.0.1",              // http address
     port: 5984,                     // http port
     secured: false,                 // https or http
     username: "<CouchDB-username>", // admin username
     password: "<CouchDB-password>"  // admin password
 )
 let couchDBClient = CouchDBClient(connectionProperties: conProperties)
 ```
 */
public class CouchDBClient {

    // MARK: Properties
    
    /// The `ConnectionProperties` for the `CouchDBClient`.
    public let connProperties: ConnectionProperties

    // MARK: Initializer
    
    /**
     Initialize a `CouchDBClient`.
     ### Usage Example: ###
     ```swift
     let couchDBClient = CouchDBClient(connectionProperties: conProperties)
     ```
     */
    /// - parameter connectionProperties: The connection properties for the CouchDB connection.
    public init(connectionProperties: ConnectionProperties) {
        self.connProperties = connectionProperties
    }

    // MARK: Databases

    /**
     Create a new `Database`.
     ### Usage Example: ###
     ```swift
     couchDBClient.createDB("NewDB") { (database, error) in
         if let database = database {
            // Use database
         }
     }
     ```
     */
    /// - parameters:
    ///     - dbName: String name of the database
    ///     - callback: Callback containing the newly created `Database` on success or a `CouchDBError` on failure.
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

    /**
     Get an existing `Database` from the CouchDB Server.
     ### Usage Example: ###
     ```swift
     couchDBClient.retrieveDB("ExistingDB") { (database, error) in
        if let database = database {
            // Use database
        }
     }
     ```
     */
    /// - parameters:
    ///     - dbName: String name of the desired `Database`.
    ///     - callback: Callback containing the desired `Database` on success or a `CouchDBError` on failure.
    public func retrieveDB(_ dbName: String, callback: @escaping (Database?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "HEAD",
                                                         path: "/\(HTTP.escape(url: dbName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                
                if response.statusCode == .OK {
                    return callback(Database(connProperties: self.connProperties, dbName: dbName), nil)
                } else {
                    return callback(nil, CouchDBError(response.statusCode))
                }
            } else {
                return callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: "No response from createDB request"))
            }
        }
        req.end()
    }
    
    /// Delete a `Database` given a local instance of it.
    /// - parameters:
    ///     - database: An instance of the `Database` to delete.
    ///     - callback: Callback containing a `CouchDBError` if one occurred.
    public func deleteDB(_ database: Database, callback: @escaping (CouchDBError?) -> ()) {
        deleteDB(database.name, callback: callback)
    }

    /// Delete a `Database` given its name.
    /**
     ### Usage Example: ###
     ```swift
     couchDBClient.deleteDB("ExistingDB") { (error) in
        if let error = error {
            // Handle the error
        }
     }
     ```
     */
    /// - parameters:
    ///     - dbName: String name of the `Database` to delete.
    ///     - callback: Callback containing a `CouchDBError` if one occurred.
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
    ///     - callback: Callback containing an array of UUIDs or a `CouchDBError` if one occured.
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
    /// - parameter callback: Callback containing the UUID or a `CouchDBError` if one occurred.
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
}
