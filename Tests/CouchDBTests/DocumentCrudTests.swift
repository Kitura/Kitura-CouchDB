/**
 * Copyright IBM Corporation 2019
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
    let documentId3 = "abcdef"
    let myDocument1 = TypeADocument(_id: "123456",
                                    _rev: nil,
                                    truncated: false,
                                    created_at: "Tue Aug 28 21:16:23 +0000 2012",
                                    favorited: false,
                                    value: "value1")
    
    let myDocument2 = TypeADocument(_id: "654321",
                                    _rev: nil,
                                    truncated: false,
                                    created_at: "Mon Aug 27 20:16:20 +0000 2012",
                                    favorited: false,
                                    value: "value2")
    let myDocument3 = TypeBDocument(_id: "abcdef",
                                    _rev: nil,
                                    otherValue: "valueA",
                                    starred: true)
    
    // Test CRUD actions in sequence. Each action calls a following action
    // in sequence, starting with document creation.
    func testCrudTest() {
        setUpDatabase {
            self.createDocument(document: self.myDocument1)
        }
    }
    
    //Create document closure
    func createDocument<D: Document>(document: D) {
        database?.create(document, callback: { (response: DocumentResponse?, error) in
            guard let documentId = response?.id else {
                return XCTFail("Error in creating document: \(String(describing: error?.description))")
            }
            if documentId == self.documentId1 {
                print(">> Successfully created the JSON document.")
                self.delay{self.createDocument(document: self.myDocument2)}
            } else if documentId == self.documentId2 {
                print(">> Successfully created the JSON document.")
                self.delay {self.createDocument(document: self.myDocument3)}
            } else {
                self.delay(self.readDocument)
            }
        })
    }
    
    //Read document
    func readDocument() {
        database?.retrieve(documentId1, callback: { (document: TypeADocument?, error) in
            guard let document = document, let id = document._id else {
                return XCTFail("Error in reading document \(String(describing: error?.statusCode)) \(String(describing: error?.description))")
            }
            let value = document.value
            XCTAssertEqual(self.documentId1, id, "Wrong documentId read from document")
            XCTAssertEqual("value1", value, "Wrong value read from document")
            print(">> Successfully read the following JSON document: ")
            print(document)
            self.delay(self.retrieveAll)
        })
    }
    
    
    // Retrieve all documents
    func retrieveAll() {
        database?.retrieveAll(includeDocuments: true, callback: { (documents: AllDatabaseDocuments?, error) in
            guard let documents = documents, documents.total_rows == 3 else {
                return XCTFail("Error in retrieving all documents \(String(describing: error?.description))")
            }
            let document1 = documents.rows[0]
            guard let id1 = document1["id"] as? String,
                let value1 = ((document1["doc"] as? [String: Any])?["value"]) as? String
                else {
                    return XCTFail("Error: Keys not found when reading document")
            }
            XCTAssertEqual(self.documentId1, id1, "Wrong documentId read from document")
            XCTAssertEqual("value1", value1, "Wrong value read from document")
            
            let document2 = documents.rows[1]
            guard let id2 = document2["id"] as? String, let value2 = ((document2["doc"] as? [String: Any])?["value"]) as? String else {
                return XCTFail("Error: Keys not found when reading document")
            }
            XCTAssertEqual(self.documentId2, id2, "Wrong documentId read from document")
            XCTAssertEqual("value2", value2, "Wrong value read from document")
            
            print(">> Successfully retrieved all documents")
            self.delay {
                self.retrieveAllTyped(documents)
            }
        })
    }
    
    func retrieveAllTyped(_ documents: AllDatabaseDocuments) {
        // ensure that objects can be strongly typed if documents are returned
        let typeADocs = documents.findAll(TypeADocument.self)
        let typeBDocs = documents.findAll(TypeBDocument.self)
        XCTAssertEqual(2, typeADocs.count, "Incorrect number of TypeADocument objects retrieved from database")
        XCTAssertEqual(1, typeBDocs.count, "Incorrect number of TypeBDocument objects retrieved from database")
        guard let myRetrievedDocA = typeADocs.first, let myRetrievedDocB = typeBDocs.first else {
            return XCTFail("Could not retrieve objects from array")
        }
        XCTAssertEqual(myRetrievedDocA.favorited, myDocument1.favorited, "Object content does not match for TypeA")
        XCTAssertEqual(myRetrievedDocB.starred, myDocument3.starred, "Object content does not match for TypeB")
        guard let retrievedID1 = myRetrievedDocA._id, let retrievedID2 = myRetrievedDocB._id else {
            return XCTFail("Could not extract id's from retrieved objects")
        }
        XCTAssertEqual(documentId1, retrievedID1, "Incorrect ID retrieved for first document")
        XCTAssertEqual(documentId3, retrievedID2, "Incorrect ID retrieved for first document")
        guard let rev1 = myRetrievedDocA._rev else {
            return XCTFail("Could not extract rev from retrieved objects")
        }
        
        database?.retrieveAll(includeDocuments: false) { emptyDocuments, error in
            guard let emptyDocuments = emptyDocuments else {
                return XCTFail("Error in retrieving all documents when includeDocuments is false \(String(describing: error?.description))")
            }
            let typeAEmpty = emptyDocuments.findAll(TypeADocument.self)
            let typeBEmpty = emptyDocuments.findAll(TypeBDocument.self)
            XCTAssertNotEqual(typeADocs.count, typeAEmpty.count, "Strongly typed document array should not return any documents if includeDocuments is false")
            XCTAssertNotEqual(typeBDocs.count, typeBEmpty.count, "Strongly typed document array should not return any documents if includeDocuments is false")
            self.delay {
                self.updateDocument(rev1)
            }
        }
    }
    
    
    //Update document
    func updateDocument(_ revisionNumber: String) {
        var newDoc = myDocument1
        newDoc.value = "value3"
        database?.update(documentId1, rev: revisionNumber, document: newDoc, callback: { (document: DocumentResponse?, error) in
            guard let document = document else {
                return XCTFail("Error in updating document \(String(describing: error?.description))")
            }
            XCTAssertEqual(self.documentId1, document.id , "Wrong documentId read from updated document")
            print(">> Successfully updated the JSON document.")
            self.delay(self.confirmUpdate)
        })
    }
    
    //Re-read document to confirm update
    func confirmUpdate() {
        database?.retrieve(documentId1, callback: { (document: TypeADocument?, error) in
            guard let document = document, let id = document._id, let rev = document._rev else {
                return XCTFail("Error in rereading document \(String(describing: error?.description))")
            }
            XCTAssertEqual(self.documentId1, id, "Wrong documentId read from updated document")
            XCTAssertEqual("value3", document.value, "Wrong value read from updated document")
            print(">> Successfully confirmed update in the JSON document")
            self.delay {
                self.deleteDocument(rev)
            }
        })
    }
    
    //Delete document
    func deleteDocument(_ revisionNumber: String) {
        database?.delete(documentId1, rev: revisionNumber, callback: { (error) in
            if let error = error {
                XCTFail("Error in rereading document \(error.description)")
            } else {
                print(">> Successfully deleted the JSON document with ID \(self.documentId1) from CouchDB.")
            }
        })
    }
}
