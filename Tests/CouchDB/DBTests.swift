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

import XCTest

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import SwiftyJSON

@testable import CouchDB

class DBTests : XCTestCase {

  static var allTests : [(String, DBTests -> () throws -> Void)] {
    return [
        ("testDB", testDB),
    ]
  }

  func testDB() {
    let credentials = Utils.readCredentials()

    // Connection properties for testing Cloudant or CouchDB instance
    let connProperties = ConnectionProperties(hostName: credentials.host,
      port: credentials.port, secured: false,
      userName: credentials.username,
      password: credentials.password)

    // Create couchDBClient instance using conn properties
    let couchDBClient = CouchDBClient(connectionProperties: connProperties)
    print("Hostname is: \(couchDBClient.connProperties.hostName)")

    couchDBClient.createDB("test_db") {(db: Database?, error: NSError?) in
        if let error = error {
            XCTFail("DB creation error: \(error.code) \(error.localizedDescription)")
        }

        guard let db = db else {
            XCTFail("Created database is nil")
            return
        }

        print(">> Database successfully created")
        couchDBClient.deleteDB(db) {(error: NSError?) in
            if let error = error {
                XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
            }
            print(">> Database successfully deleted")
        }
    }
  }

 }
