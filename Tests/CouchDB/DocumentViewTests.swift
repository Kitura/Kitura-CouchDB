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

class DocumentViewTests : XCTestCase {

    static var allTests : [(String, DocumentCrudTests -> () throws -> Void)] {
        return [
            ("testViewTest", testViewTest)
        ]
    }

    var database: Database?
    let documentId = "123456"
    var jsonDocument: JSON?
    let dbName = "kitura_db"

    func testCrudTest() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
            port: credentials.port, secured: false,
            username: credentials.username,
            password: credentials.password)

        // Create couchDBClient instance using conn properties
        let couchDBClient = CouchDBClient(connectionProperties: connProperties)
        print("Hostname is: \(couchDBClient.connProperties.host)")

        // Check if DB exists
        couchDBClient.dbExists(dbName) {exists, error in
            if let error = error  {
                XCTFail("Failed checking existence of database \(self.dbName)")
            }
            else {
                if  exists  {
                    // Create database handle to perform any document operations
                    self.database = couchDBClient.database(self.dbName)

                    // Start tests...
                    self.createDocument()
                }
                else {
                    // Create database
                    couchDBClient.createDB(self.dbName) {db, error in
                        if  error != nil  {
                            XCTFail("Failed creating the database \(self.dbName)")
                        }
                        else {
                            self.database = db

                            // Start tests...
                            self.createDocument()
                        }
                    }
                }
            }
        }
    }

    func chainer(_ document: JSON?, next: (revisionNumber: String) -> Void) {
        if let revisionNumber = document?["rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber: revisionNumber)
        }
        else if let revisionNumber = document?["_rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber: revisionNumber)
        }
        else {
            XCTFail(">> Oops something went wrong... could not get revisionNumber!")
        }
    }

    //Delete document
    func deleteDocument(_ revisionNumber: String) {
        database!.delete(documentId, rev: revisionNumber, failOnNotFound: true, callback: { (error: NSError?) in
            if let error = error {
                XCTFail("Error in rereading document \(error.code) \(error.domain) \(error.userInfo)")
            }
            else {
                print(">> Successfully deleted the JSON document with ID \(self.documentId) from CouchDB.")
            }
        })
    }

    //Read document
    func readDocument() {
        let key = "viewTest"
        database!.queryByView("matching", design: "test", params: [.Keys([key])]) { (document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in querying by view document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                guard let row = document["rows"].first as JSON!, id = row["_id"].string, value = row["value"].string else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                
                XCTAssertEqual(self.documentId, id, "Wrong documentId read from document")
                XCTAssertEqual(key, value, "Wrong value read from document")
                
                print(">> Successfully read the following JSON document: ")
                print(document)
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
        #if os(Linux)
        let jsonData = jsonStr.bridge().dataUsingEncoding(NSUTF8StringEncoding)
        #else
        let jsonData = jsonStr.bridge().data(using: NSUTF8StringEncoding)
        #endif
        // Convert NSData to JSON object
        jsonDocument = JSON(data: jsonData!)
        database!.create(jsonDocument!, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in creating document \(error.code) \(error.domain) \(error.userInfo)")
            }
            else {
                print(">> Successfully created the JSON document.")
                self.createDesign()
            }
        })
    }
    
    func createDesign() {
        let name = "test"
        let designDocument = JSON(["_id" : "_design/\(name)",
            "views" : [
                "matching" : [
                    "map" : "function(doc) { emit(doc.value, doc); }"
                ]
            ]
            ])

        database!.createDesign(name, document: designDocument) { (document: JSON?, error: NSError?) in
            if let error = error {
                XCTFail("Error in creating document \(error.code) \(error.domain) \(error.userInfo)")
            }
            else {
                print(">> Successfully created the design.")
                self.readDocument()
            }
        }
    }
}
