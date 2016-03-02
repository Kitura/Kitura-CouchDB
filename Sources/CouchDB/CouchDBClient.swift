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

public class CouchDBClient {

  public let connProperties: ConnectionProperties

  public init(connectionProperties: ConnectionProperties) {
    self.connProperties = connectionProperties
  }

  public func database(dbName: String) -> Database {
      return Database(connProperties: self.connProperties, dbName: dbName)
  }

  public func createDB(dbName: String, callback: (Database?, NSError?) -> ()) {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(Http.escapeUrl(dbName))", hasBody: false)
      let req = Http.request(requestOptions) { response in
          var error: NSError?
          var db: Database?
          if let response = response {
              if response.statusCode == HttpStatusCode.CREATED {
                  db = Database(connProperties: self.connProperties, dbName: dbName)
              }
              else {
                  error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
              }
          }
          else {
              error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
          }
          callback(db, error)
      }
      req.end()
  }

  public func dbExists(dbName: String, callback: (Bool, NSError?) -> ()) {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET", path: "/\(Http.escapeUrl(dbName))", hasBody: false)
      let req = Http.request(requestOptions) { response in
          var error: NSError?
          var exists = false
          if let response = response {
              if response.statusCode == HttpStatusCode.OK {
                  exists = true
              }
          }
          else {
              error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
          }
          callback(exists, error)
      }
      req.end()
  }

  public func deleteDB(db: Database, callback: (NSError?) -> ()) {
      deleteDB(db.name, callback: callback)
  }

  public func deleteDB(dbName: String, callback: (NSError?) -> ()) {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(Http.escapeUrl(dbName))", hasBody: false)
      let req = Http.request(requestOptions) { response in
          var error: NSError?
          if let response = response {
              if response.statusCode != HttpStatusCode.OK {
                  error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
              }
          }
          else {
              error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
          }
          callback(error)
      }
      req.end()
  }

}
