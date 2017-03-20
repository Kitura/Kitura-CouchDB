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

class UUIDTests : XCTestCase {

    static var allTests: [(String, (UUIDTests) -> () throws -> Void)] {
        return [
            ("testUUIDsTest", testUUIDsTest),
            ("testUUIDTest", testUUIDTest),
        ]
    }

    func testUUIDsTest() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
                                                  port: credentials.port, secured: false,
                                                  username: credentials.username,
                                                  password: credentials.password)

        // Create couchDBClient instance using conn properties
        let couchDBClient = CouchDBClient(connectionProperties: connProperties)

        print("Hostname is: \(couchDBClient.connProperties.host)")

        let expectedCount : UInt = 10
        couchDBClient.getUUIDs(count: expectedCount) { (uuids, error) in

            if error != nil {
                XCTFail("Failed to retrieve \(expectedCount) UUIDs: \(String(describing: error))")
            } else {
                if let uuids = uuids {

                    XCTAssertEqual(uuids.count, Int(expectedCount), "Expected count of UUIDs to be \(expectedCount), instead it is \(uuids.count)")
                    print(">> Successfully retrieved \(expectedCount) UUIDs")
                } else {
                    XCTFail("Failed to retrieve \(expectedCount) UUIDs, nil retrieved")
                }
            }
        }
    }

    func testUUIDTest() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
                                                  port: credentials.port, secured: false,
                                                  username: credentials.username,
                                                  password: credentials.password)

        // Create couchDBClient instance using conn properties
        let couchDBClient = CouchDBClient(connectionProperties: connProperties)

        print("Hostname is: \(couchDBClient.connProperties.host)")

        couchDBClient.getUUID() { (uuid, error) in

            if error != nil {
                XCTFail("Failed to retrieve a UUID: \(String(describing: error))")
            } else {
                if uuid != nil {

                    print(">> Successfully retrieved a UUID")
                } else {
                    XCTFail("Failed to retrieve a UUID, nil retrieved")
                }
            }
        }
    }

}
