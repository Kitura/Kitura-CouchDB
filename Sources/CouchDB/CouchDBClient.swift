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
}
