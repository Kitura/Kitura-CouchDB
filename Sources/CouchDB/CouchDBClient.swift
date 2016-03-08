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
    public func database(dbName: String) -> Database {
        return Database(connProperties: self.connProperties, dbName: dbName)
    }

    ///
    /// Create a new database
    ///
    /// - Parameter dbName: String for the name of the database
    /// - Parameter callback: a function containing the Database instance
    ///
    public func createDB(dbName: String, callback: (Database?, NSError?) -> ()) {
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
                        errorDesc: JSON.parse(desc), id: nil, rev: nil)
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
    public func dbExists(dbName: String, callback: (Bool, NSError?) -> ()) {
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
    public func deleteDB(database: Database, callback: (NSError?) -> ()) {
      deleteDB(database.name, callback: callback)
    }

    ///
    /// Delete a database by name
    ///
    /// - Parameter dbName: a String for the name of the database
    /// - Parameter callback: a function containing an NSError? if a problem occurred
    ///
    public func deleteDB(dbName: String, callback: (NSError?) -> ()) {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE",
        path: "/\(Http.escapeUrl(dbName))", hasBody: false)
      let req = Http.request(requestOptions) { response in
          var error: NSError?
          if let response = response {
              if response.statusCode != HttpStatusCode.OK {
                  if let descOpt = try? response.readString(), let desc = descOpt {
                    error = CouchDBUtils.createError(response.statusCode,
                        errorDesc: JSON.parse(desc), id: nil, rev: nil)
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

}
