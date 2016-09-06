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

class DocumentViewTests: XCTestCase {

    static var allTests: [(String, (DocumentViewTests) -> () throws -> Void)] {
        return [
                   ("testViewTest", testViewTest)
        ]
    }

    var database: Database?
    let documentId = "123456"
    var jsonDocument: JSON?
    // To enable running Linux and OSX tests in parallel
    #if os(Linux)
    let dbName = "kitura_db_linux"
    #else
    let dbName = "kitura_db"
    #endif
    var couchDBClient: CouchDBClient?

    func testViewTest() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
                                                  port: credentials.port, secured: false,
                                                  username: credentials.username,
                                                  password: credentials.password)

        // Create couchDBClient instance using conn properties
        couchDBClient = CouchDBClient(connectionProperties: connProperties)
        guard let couchDBClient = couchDBClient  else {
            XCTFail("Failed to create CouchDB Client.")
            exit(1)
        }

        print("Hostname is: \(couchDBClient.connProperties.host)")

        // Check if DB exists
        couchDBClient.dbExists(dbName) {exists, error in
            if  error != nil {
                XCTFail("Failed checking existence of database \(self.dbName). Error=\(error!.localizedDescription)")
            } else {
                if  exists {
                    // Delete the old database and then re-create it to avoid state issues
                    let db = couchDBClient.database(self.dbName)
                    couchDBClient.deleteDB(db) {error in
                        if let error = error {
                            XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
                        } else {
                            // Create database
                            self.createDatabase()
                        }
                    }
                } else {
                    // Create database
                    self.createDatabase()
                }
            }
        }
    }

    // Create Database closure
    func createDatabase() {
        guard let couchDBClient = couchDBClient  else {
            XCTFail("Failed to create CouchDB Client.")
            return
        }

        couchDBClient.createDB(self.dbName) {db, error in
            if  error != nil {
                XCTFail("Failed creating the database \(self.dbName). Error=\(error!.localizedDescription)")
                exit(1)
            } else {
                self.database = db

                // Start tests...
                self.createDocument()
            }
        }
    }

    func chainer(_ document: JSON?, next: (_ revisionNumber: String) -> Void) {
        if let revisionNumber = document?["rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber)
        } else if let revisionNumber = document?["_rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber)
        } else {
            XCTFail(">> Oops something went wrong... could not get revisionNumber!")
        }
    }

    //Read document
    func readDocument() {
#if os(Linux)
        let key = "viewTest"
#else
        let key: NSString = "viewTest"
#endif
        database!.queryByView("matching", ofDesign: "test", usingParameters: [.keys([key])]) { (document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in querying by view document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                guard let id = document!["rows"][0]["id"].string, let value = document!["rows"][0]["value"]["value"].string, value == "viewTest" else {
                    XCTFail("Error: Keys not found when reading document")
                    exit(1)
                }

                XCTAssertEqual(self.documentId, id, "Wrong documentId read from document")
                XCTAssertEqual(key as String, value, "Wrong value read from document")

                print(">> Successfully read the following JSON document: ")
                print(document!)
            }
        }
    }

    //Create document closure
    func createDocument() {
        // JSON document in string format
        let jsonStr =
            "{" +
                "\"_id\": \"\(documentId)\"," +
                "\"coordinates\": null," +
                "\"truncated\": false," +
                "\"created_at\": \"Tue Aug 28 21:16:23 +0000 2012\"," +
                "\"favorited\": false," +
                "\"value\": \"viewTest\"" +
        "}"

        // Convert JSON string to NSData
        let jsonData = jsonStr.data(using: .utf8)
        // Convert NSData to JSON object
        jsonDocument = JSON(data: jsonData!)
        database!.create(jsonDocument!, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in creating document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                print(">> Successfully created the JSON document.")
                self.createDesign()
            }
        })
    }

    func createDesign() {
        let name = "test"
        #if os(Linux)
            let designDocument: [String:Any] =
                ["_id" : "_design/\(name)",
                 "views" : [
                               "matching" : [
                                                "map" : "function(doc) { emit(doc.value, doc); }"
                    ]
                    ]
            ]
        #else
            let designDocument: [String:Any] =
                ["_id" : "_design/\(name)" as NSString,
                 "views" : [
                               "matching" : [
                                                "map" : "function(doc) { emit(doc.value, doc); }"
                    ]
                    ]
            ]
        #endif
        database!.createDesign(name, document: JSON(designDocument)) { (document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in creating document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                print(">> Successfully created the design.")
                self.readDocument()
            }
        }
    }
}
