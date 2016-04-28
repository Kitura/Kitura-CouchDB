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

class DocumentCrudTests : XCTestCase {

    static var allTests : [(String, DocumentCrudTests -> () throws -> Void)] {
        return [
                   ("testCrudTest", testCrudTest)
        ]
    }

    var database: Database?
    let documentId = "123456"
    var jsonDocument: JSON?
    let dbName = "kitura_db"

    func getDatabaseClient() {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
                                                  port: credentials.port, secured: false,
                                                  username: credentials.username,
                                                  password: credentials.password)

        // Create couchDBClient instance using conn properties
        let couchDBClient = CouchDBClient(connectionProperties: connProperties)
        print("Hostname is: \(couchDBClient.connProperties.host)")

        return couchDBClient
    }

    func testCrudTest() {
        // Create couchDBClient instance using conn properties
        let couchDBClient = getDatabaseClient()

        // Check if DB exists
        couchDBClient.dbExists(dbName) {exists, error in
            guard error == nil else {
                XCTFail("Failed checking existence of database \(self.dbName)")
                return
            }
            if  exists  {
                // Create database handle to perform any document operations
                self.database = couchDBClient.database(self.dbName)

                // Start tests...
                self.createDocument()
                self.setDatabaseConfig()
            }
            else {
                // Create database
                couchDBClient.createDB(self.dbName) {db, error in
                    guard error == nil else {
                        XCTFail("Failed creating the database \(self.dbName)")
                        return
                    }
                    self.database = db

                    // Start tests...
                    self.createDocument()
                    self.setDatabaseConfig()
                }
            }
        }
    }

    func chainer(document: JSON?, next: (revisionNumber: String) -> Void) {
        if let revisionNumber = document?["rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber: revisionNumber)
        } else if let revisionNumber = document?["_rev"].string {
            print("revisionNumber is \(revisionNumber)")
            next(revisionNumber: revisionNumber)
        } else {
            XCTFail(">> Oops something went wrong... could not get revisionNumber!")
        }
    }

    //Delete document
    func deleteDocument(revisionNumber: String) {
        database!.delete(documentId, rev: revisionNumber, failOnNotFound: true, callback: { (error: NSError?) in
            if (error != nil) {
                XCTFail("Error in rereading document \(error!.code) \(error!.domain) \(error!.userInfo)")

            } else {
                print(">> Successfully deleted the JSON document with ID \(self.documentId) from CouchDB.")
            }
        })
    }

    //Re-read document to confirm update
    func confirmUpdate() {
        database!.retrieve(documentId, callback: { (document: JSON?, error: NSError?) in
            if error != nil {
                XCTFail("Error in rereading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["_id"].string,
                    let value = document["value"].string else {
                        XCTFail("Error: Keys not found when rereading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId, id, "Wrong documentId read from updated document")
                XCTAssertEqual("value2", value, "Wrong value read from updated document")
                print(">> Successfully confirmed update in the JSON document")
                self.chainer(document, next: self.deleteDocument)
            }
        })
    }

    //Update document
    func updateDocument(revisionNumber: String) {
        //var json = JSON(data: jsonData!)
        jsonDocument!["value"] = "value2"
        database!.update(documentId, rev: revisionNumber, document: jsonDocument!, callback: { (rev: String?, document: JSON?, error: NSError?) in
            if (error != nil) {
                XCTFail("Error in updating document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["id"].string else {
                        XCTFail("Error: Keys not found when reading updated document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId, id, "Wrong documentId read from updated document")
                print(">> Successfully updated the JSON document.")
                self.confirmUpdate()
            }
        })
    }

    //Read document
    func readDocument() {
        database!.retrieve(documentId, callback: { (document: JSON?, error: NSError?) in
            if error != nil {
                XCTFail("Error in reading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document as JSON!,
                    let id = document["_id"].string,
                    let value = document["value"].string else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId, id, "Wrong documentId read from document")
                XCTAssertEqual("value1", value, "Wrong value read from document")
                print(">> Successfully read the following JSON document: ")
                print(document)
                self.chainer(document, next: self.updateDocument)
            }
        })
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
                "\"value\": \"value1\"" +
        "}"

        // Convert JSON string to NSData
        #if os(Linux)
            let jsonData = jsonStr.bridge().dataUsingEncoding(NSUTF8StringEncoding)
        #else
            let jsonData = jsonStr.bridge().data(usingEncoding: NSUTF8StringEncoding)
        #endif
        // Convert NSData to JSON object
        jsonDocument = JSON(data: jsonData!)
        database!.create(jsonDocument!, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
            if (error != nil) {
                XCTFail("Error in creating document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                print(">> Successfully created the JSON document.")
                self.readDocument()
            }
        })
    }

    // Database configuration
    func setDatabaseConfig() {
        print(">> Configuring the database.")
        let couchDBClient = getDatabaseClient()
        let path = "couch_httpd_auth/allow_persistent_cookies"

        checkDatabase(couchDBClient, path: path, nil) { setValue in
            couchDBClient.setConfig("couch_httpd_auth/allow_persistent_cookies", value: newValue) { (error) in
                guard error == nil else {
                    XCTFail("Error in configuring the database --> \(error!.code) \(error!.domain) \(error!.userInfo)")
                    return
                }

                checkDatabase(couchDBClient, path: path, nil) { setValue in
                    guard value != nil else {
                        XCTFail("Error getting a config value")
                        return
                    }
                    print(">> Successfully configured the database.")
                }
            }
        }
    }

    func checkDatabase(client: CouchDBClient, path: String, value: String?, callback: (String?) -> ()) {
        couchDBClient.getConfig(path) { (document, error) in
            guard error == nil else {
                XCTFail("Error getting a config value --> \(error!.code) \(error!.domain) \(error!.userInfo)")
                callback(nil)
                return
            }

            guard let setValue = document?.string else {
                XCTFail("Error getting a config value --> \(document)")
                callback(nil)
                return
            }

            guard setValue == newValue && value != nil else {
                XCTFail("Error value was already set")
                callback(nil)
                return
            }

            callback(setValue)
        }
    }
}
