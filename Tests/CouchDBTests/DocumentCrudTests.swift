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

import XCTest

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import SwiftyJSON

@testable import CouchDB

class DocumentCrudTests: XCTestCase {

    static var allTests: [(String, (DocumentCrudTests) -> () throws -> Void)] {
        return [
            ("testCrudTest", testCrudTest)
        ]
    }

    var database: Database?
    let documentId1 = "123456"
    let documentId2 = "654321"
    var jsonDocument: JSON?
    // JSON document in string format
    let jsonString1 =
        "{" +
            "\"_id\": \"123456\"," +
            "\"coordinates\": null," +
            "\"truncated\": false," +
            "\"created_at\": \"Tue Aug 28 21:16:23 +0000 2012\"," +
            "\"favorited\": false," +
            "\"value\": \"value1\"" +
    "}"
    let jsonString2 =
        "{" +
            "\"_id\": \"654321\"," +
            "\"coordinates\": null," +
            "\"truncated\": false," +
            "\"created_at\": \"Mon Aug 27 20:16:20 +0000 2012\"," +
            "\"favorited\": false," +
            "\"value\": \"value2\"" +
    "}"

    // The database name should be defined in an environment variable TESTDB_NAME
    // in Travis, to allow each Travis build to use a separate database.
    let dbName = ProcessInfo.processInfo.environment["TESTDB_NAME"] ?? "Error-TESTDB_NAME-not-set"

    var couchDBClient: CouchDBClient?

    func testCrudTest() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
            port: credentials.port, secured: true,
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

    func chainer(_ document: JSON?, next: (String) -> Void) {
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

    //Delete document
    func deleteDocument(_ revisionNumber: String) {
        database!.delete(documentId1, rev: revisionNumber, failOnNotFound: true, callback: { (error: NSError?) in
            if (error != nil) {
                XCTFail("Error in rereading document \(error!.code) \(error!.domain) \(error!.userInfo)")

            } else {
                print(">> Successfully deleted the JSON document with ID \(self.documentId1) from CouchDB.")
            }
        })
    }

    //Re-read document to confirm update
    func confirmUpdate() {
        database!.retrieve(documentId1, callback: { (document: JSON?, error: NSError?) in
            if error != nil {
                XCTFail("Error in rereading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["_id"].string,
                    let value = document["value"].string else {
                        XCTFail("Error: Keys not found when rereading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from updated document")
                XCTAssertEqual("value2", value, "Wrong value read from updated document")
                print(">> Successfully confirmed update in the JSON document")
                self.chainer(document, next: self.deleteDocument)
            }
        })
    }

    //Update document
    func updateDocument(_ revisionNumber: String) {
        //var json = JSON(data: jsonData!)
        jsonDocument!["value"] = "value2"
        database!.update(documentId1, rev: revisionNumber, document: jsonDocument!, callback: { (rev: String?, document: JSON?, error: NSError?) in
            if (error != nil) {
                XCTFail("Error in updating document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["id"].string else {
                        XCTFail("Error: Keys not found when reading updated document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from updated document")
                print(">> Successfully updated the JSON document.")
                self.confirmUpdate()
            }
        })
    }

    //Read document
    func readDocument() {
        database!.retrieve(documentId1, callback: { (document: JSON?, error: NSError?) in
            if error != nil {
               XCTFail("Error in reading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["_id"].string,
                    let value = document["value"].string else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from document")
                XCTAssertEqual("value1", value, "Wrong value read from document")
                print(">> Successfully read the following JSON document: ")
                print(document)
                self.retrieveAll()
            }
        })
    }

    // Retrieve all documents
    func retrieveAll() {
        database!.retrieveAll(includeDocuments: true, callback: { (document: JSON?, error: NSError?) in
            if error != nil {
                XCTFail("Error in retrieving all documents \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let totalRows = document["total_rows"].number, totalRows == 2 else {
                        XCTFail("Error: Wrong number of documents")
                        exit(1)
                }
                let document1 = document["rows"][0]["doc"]
                guard let id1 = document1["_id"].string,
                    let value1 = document1["value"].string else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id1, "Wrong documentId read from document")
                XCTAssertEqual("value1", value1, "Wrong value read from document")

                let document2 = document["rows"][1]["doc"]
                guard let id2 = document2["_id"].string,
                    let value2 = document2["value"].string else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId2, id2, "Wrong documentId read from document")
                XCTAssertEqual("value2", value2, "Wrong value read from document")
                print(">> Successfully retrieved all documents")
                self.chainer(document1, next: self.updateDocument)
            }
        })
    }

    //Create document closure
    func createDocument(fromJSONString jsonString: String) {
       // Convert JSON string to NSData
        let jsonData = jsonString.data(using: .utf8)
        // Convert NSData to JSON object
        jsonDocument = JSON(data: jsonData!)
        database!.create(jsonDocument!, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
            if (error != nil) {
                XCTFail("Error in creating document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                print(">> Successfully created the JSON document.")
                if let documentId = id, documentId == self.documentId1 {
                    self.createDocument(fromJSONString: self.jsonString2)
                } else {
                    self.readDocument()
                }
            }
        })
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
                self.createDocument(fromJSONString: self.jsonString1)
            }
        }
    }
}
