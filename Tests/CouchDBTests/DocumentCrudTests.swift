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

@testable import CouchDB

class DocumentCrudTests: CouchDBTest {

    static var allTests: [(String, (DocumentCrudTests) -> () throws -> Void)] {
        return [
            ("testCrudTest", testCrudTest)
        ]
    }

    let documentId1 = "123456"
    let documentId2 = "654321"
    let myDocument1 = MyDocument(_id: "123456",
                                 _rev: nil,
                                 truncated: false,
                                 created_at: "Tue Aug 28 21:16:23 +0000 2012",
                                 favorited: false,
                                 value: "value1")
    
    let myDocument2 = MyDocument(_id: "654321",
                                 _rev: nil,
                                 truncated: false,
                                 created_at: "Mon Aug 27 20:16:20 +0000 2012",
                                 favorited: false,
                                 value: "value2")

    // Test CRUD actions in sequence. Each action calls a following action
    // in sequence, starting with document creation.
    func testCrudTest() {
        setUpDatabase {
            self.createDocument(document: self.myDocument1)
        }
    }
    
    //Create document closure
    func createDocument<D: Document>(document: D) {
        database?.create(document, callback: { (response: CouchResponse?, error: NSError?) in
            if (error != nil) {
                XCTFail("Error in creating document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                if let documentId = response?.id, documentId == self.documentId1 {
                    print(">> Successfully created the JSON document.")
                    self.delay{self.createDocument(document: self.myDocument2)}
                } else {
                    self.delay(self.readDocument)
                }
            }
        })
    }

    //Read document
    func readDocument() {
        database?.retrieve(documentId1, callback: { (document: MyDocument?, error: NSError?) in
            if error != nil {
                XCTFail("Error in reading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let document = document, let id = document._id else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                let value = document.value
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from document")
                XCTAssertEqual("value1", value, "Wrong value read from document")
                print(">> Successfully read the following JSON document: ")
                print(document)
                self.delay(self.retrieveAll)
            }
        })
    }
    
    
    // Retrieve all documents
    func retrieveAll() {
        database?.retrieveAll(includeDocuments: true, callback: { (documents: AllDatabaseDocuments?, error: NSError?) in
            if error != nil {
                XCTFail("Error in retrieving all documents \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                guard let documents = documents,
                    documents.total_rows == 2 else {
                        XCTFail("Error: Wrong number of documents")
                        exit(1)
                }
                let document1 = documents.rows[0]
                guard let id1 = document1["id"] as? String,
                    let value1 = ((document1["doc"] as? [String: Any])?["value"]) as? String,
                    let rev1 = ((document1["doc"] as? [String: Any])?["_rev"]) as? String
                    else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id1, "Wrong documentId read from document")
                XCTAssertEqual("value1", value1, "Wrong value read from document")
                
                let document2 = documents.rows[1]
                guard let id2 = document2["id"] as? String,
                    let value2 = ((document2["doc"] as? [String: Any])?["value"]) as? String else {
                        XCTFail("Error: Keys not found when reading document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId2, id2, "Wrong documentId read from document")
                XCTAssertEqual("value2", value2, "Wrong value read from document")
                print(">> Successfully retrieved all documents")
                self.delay {
                    self.updateDocument(rev1)
                }
            }
        })
    }
    
    
    //Update document
    func updateDocument(_ revisionNumber: String) {
        var newDoc = myDocument1
        newDoc.value = "value3"
        database?.update(documentId1, rev: revisionNumber, document: newDoc, callback: { (document: CouchResponse?, error: NSError?) in
            if let error = error {
                XCTFail("Error in updating document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                guard let document = document,
                    let id = document.id else {
                        XCTFail("Error: Keys not found when reading updated document")
                        exit(1)
                }
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from updated document")
                print(">> Successfully updated the JSON document.")
                self.delay(self.confirmUpdate)
            }
        })
    }

    //Re-read document to confirm update
    func confirmUpdate() {
        database?.retrieve(documentId1, callback: { (document: MyDocument?, error: NSError?) in
            if let error = error {
                XCTFail("Error in rereading document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                guard let document = document, let id = document._id, let rev = document._rev else {
                    XCTFail("Error: Keys not found when rereading document")
                    exit(1)
                }
                XCTAssertEqual(self.documentId1, id, "Wrong documentId read from updated document")
                XCTAssertEqual("value3", document.value, "Wrong value read from updated document")
                print(">> Successfully confirmed update in the JSON document")
                self.delay {
                    self.deleteDocument(rev)
                }
            }
        })
    }
    
    //Delete document
    func deleteDocument(_ revisionNumber: String) {
        database?.delete(documentId1, rev: revisionNumber, failOnNotFound: true, callback: { (error: NSError?) in
            if (error != nil) {
                XCTFail("Error in rereading document \(error!.code) \(error!.domain) \(error!.userInfo)")
            } else {
                print(">> Successfully deleted the JSON document with ID \(self.documentId1) from CouchDB.")
            }
        })
    }
}
