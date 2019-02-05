/**
 * Copyright IBM Corporation 2016, 2017, 2019
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

class DocumentBulkUpdateTests: CouchDBTest {

    // Add an additional class variable holding all tests for Linux compatibility
    static var allTests: [(String, (DocumentBulkUpdateTests) -> () throws -> Void)] {
        return [
            ("testBulkInsert", testBulkInsert),
            ("testBulkUpdate", testBulkUpdate),
            ("testBulkDelete", testBulkDelete),
            ("testCodableBulkDelete", testCodableBulkDelete),
        ]
    }

    // MARK: - Database test objects

    let json1 = ["_id": "1234567",
                "type": "user",
                "firstName": "John",
                "lastName": "Doe",
                "birthdate": "1985-01-23"]
    
    let json2 = ["_id": "8901234",
                "type": "user",
                "firstName": "Mike",
                "lastName": "Wazowski",
                "birthdate": "1981-09-04"]
    
    let json3 = ["_id": "5678901",
                "type": "address",
                "name": "139 Edgefield St. Honolulu, HI 96815",
                "country": "United States",
                "city": "Honolulu",
                "latitude": 21.319820,
                "longitude": -157.865501] as [String : Any]
    let json4 = ["_id": "2345678",
                "type": "address",
                "name": "79 Pumpkin Hill Road Monstropolis, MN 37803",
                "country": "United States",
                "city": "Monstropolis",
                "latitude": 44.961098,
                "longitude": -93.176732] as [String : Any]
    let json5 = ["_id": "9012345",
                "type": "userAddress",
                "userId": "1234567",
                "addressId": "5678901"]
    let json6 = ["_id": "6789012",
                "type": "userAddress",
                "userId": "8901234",
                "addressId": "2345678"]

    let bulkDoc1 = BulkTest(_id: "bulk123",
                                 _rev: nil,
                                 _deleted: false,
                                 value: "value1")
    let bulkDoc2 = BulkTest(_id: "bulk456",
                            _rev: nil,
                            _deleted: false,
                            value: "value2")
    let bulkDoc3 = BulkTest(_id: "bulk789",
                            _rev: nil,
                            _deleted: false,
                            value: "value3")
    
    // MARK: - Xcode tests

    func testBulkInsert() {
        setUpDatabase() {
            guard let database = self.database else {
                XCTFail("Failed to retrieve database")
                return
            }

            let documents = [self.json1, self.json2, self.json3, self.json4, self.json5, self.json6]

            // Bulk insert documents
            database.bulk(documents: BulkDocuments(docs: documents)) { bulkResponse, error in
                guard let bulkResponse = bulkResponse else {
                    return XCTFail("Failed to bulk insert documents into database, error: \(String(describing: error?.localizedDescription))")
                }

                XCTAssert(bulkResponse.count == documents.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

                // Get all documents and compare their number to match the inserted number of documents
                database.retrieveAll() { bulkResponse, error in
                    guard let retrievedDocuments = bulkResponse?.rows else {
                        return XCTFail("Failed to retrieve all documents, error: \(String(describing: error?.localizedDescription))")
                    }

                    XCTAssert(retrievedDocuments.count == documents.count, "Incorrect number of documents retrieved, error: Couldn't insert all documents")
                }
            }
        }
    }

    func testBulkUpdate() {
        setUpDatabase() {
            guard let database = self.database else {
               return XCTFail("Failed to retrieve database")
            }

            let documentsToInsert = [self.json1, self.json3, self.json5]
            let documentsToUpdate = [self.json2, self.json4, self.json6]

            // Bulk insert documents
            database.bulk(documents: BulkDocuments(docs: documentsToInsert)) { bulkResponse, error in
                guard let bulkResponse = bulkResponse else {
                    return XCTFail("Failed to bulk insert documents into database, error: \(String(describing: error?.localizedDescription))")
                }

                XCTAssert(bulkResponse.count == documentsToInsert.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

                // Assign same ID and REV numbers to documents to update
                let documentsToUpdate: [[String: Any]] = documentsToUpdate.enumerated().map {
                    var doc = $1
                    doc["_id"] = bulkResponse[$0].id
                    doc["_rev"] = bulkResponse[$0].rev
                    return doc
                }

                // Bulk update documents
                database.bulk(documents: BulkDocuments(docs: documentsToUpdate)) { bulkResponse, error in
                    guard let bulkResponse = bulkResponse else {
                        return XCTFail("Failed to bulk insert documents into database, error: \(String(describing: error?.localizedDescription))")
                    }
                    
                    // Check if all documents were updated successfully
                    guard (bulkResponse.reduce(true) { $0 && ($1.ok ?? false) }) == true else {
                        return XCTFail("Failed to bulk update documents from database, error: Not all documents were updated successfully")
                    }

                    // Get all documents and compare their contents to match the updated documents
                    database.retrieveAll(includeDocuments: true) { bulkResponse, error in
                        guard let retrievedDocuments = bulkResponse?.rows else {
                            return XCTFail("Failed to retrieve all documents, error: \(String(describing: error?.localizedDescription))")
                        }

                        // Check if all retrieved documents match the updated documents
                        let success = retrievedDocuments.reduce(true) { result, doc1 in
//                            // Get document with the same ID as this one
                            guard let doc2 = (documentsToUpdate.first() {
                                $0["_id"] as? String == doc1["id"] as? String
                            }) else {
                                return false
                            }

                            // Loop through all keys and values in document 1 and compare them to document 2
                            var comparisonResult = true
                            (doc1["doc"] as? [String: Any])?.forEach {
                                // Ignore REV field since it is modified after updating the documents
                                if $0 != "_rev" {
                                    comparisonResult = comparisonResult && ($1 as? String == doc2[$0] as? String)
                                }
                            }
                            return result && comparisonResult
                        }

                        XCTAssert(success, "Failed to bulk update documents from database, error: Updated documents do not match to the retrieved ones")
                    }
                }
            }
        }
    }

    func testBulkDelete() {
        setUpDatabase() {
            guard let database = self.database else {
                return XCTFail("Failed to retrieve database")
            }

            let documents = [self.json4, self.json6, self.json5, self.json1, self.json3, self.json2]

            // Bulk insert documents
            database.bulk(documents: BulkDocuments(docs: documents)) { bulkResponse, error in
                guard let bulkResponse = bulkResponse else {
                    return XCTFail("Failed to bulk insert documents into database, error: \(String(describing: error?.localizedDescription))")
                }

                XCTAssert(bulkResponse.count == documents.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

                // Get all documents and build the payload sent for bulk deletion
                database.retrieveAll() { bulkResponse, error in
                    guard let retrievedDocuments = bulkResponse?.rows else {
                        return XCTFail("Failed to retrieve all documents, error: \(String(describing: error?.localizedDescription))")
                    }
                    
                    XCTAssert(retrievedDocuments.count == documents.count, "Incorrect number of documents retrieved, error: Couldn't insert all documents")

                    // Build the payload sent for bulk deletion by extracting ID and REV values from the retrieved JSON array
                    let documentsToDelete = retrievedDocuments.map() {
                        ["_id": $0["id"] as Any, "_rev": ($0["value"] as? [String: Any])?["rev"] as Any, "_deleted": true as Any]
                    } as [[String : Any]]
                
                    // Bulk delete documents
                    database.bulk(documents: BulkDocuments(docs: documentsToDelete)) { bulkResponse, error in
                        guard let bulkResponse = bulkResponse else {
                            return XCTFail("Failed to bulk delete documents from database, error: \(String(describing: error?.localizedDescription))")
                        }

                        // Check if all documents were deleted successfully
                        guard (bulkResponse.reduce(true) { $0 && ($1.ok ?? false) }) == true else {
                            return XCTFail("Failed to bulk delete documents from database, error: Not all documents were deleted successfully")
                        }

                        // Get all documents (there should be none)
                        database.retrieveAll() { bulkResponse, error in
                            if let error = error {
                                return XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
                            }
                            XCTAssert(bulkResponse?.rows.count == 0, "Failed to bulk delete documents from database, error: Not all documents were deleted")
                        }
                    }
                }
            }
        }
    }
    
    func testCodableBulkDelete() {
        setUpDatabase() {
            guard let database = self.database else {
                return XCTFail("Failed to retrieve database")
            }
            
            guard let documents = try? BulkDocuments(encoding: [self.bulkDoc1, self.bulkDoc2, self.bulkDoc3]) else {
                return XCTFail("Failed to encode documents")
            }
            
            // Bulk insert documents
            database.bulk(documents:  documents) { bulkResponse, error in
                guard let bulkResponse = bulkResponse else {
                    return XCTFail("Failed to bulk insert documents into database, error: \(String(describing: error?.localizedDescription))")
                }
                
                XCTAssert(bulkResponse.count == documents.docs.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")
                
                // Get all documents and build the payload sent for bulk deletion
                database.retrieveAll(includeDocuments: true) { bulkResponse, error in
                    guard let retrievedDocuments = bulkResponse?.decodeDocuments(ofType: BulkTest.self) else {
                        return XCTFail("Failed to decode all documents, error: \(String(describing: error?.localizedDescription))")
                    }
                    
                    XCTAssert(retrievedDocuments.count == documents.docs.count, "Incorrect number of documents retrieved, error: Couldn't insert all documents")
                    
                    let documentsToDelete = retrievedDocuments.map() {
                        BulkTest(_id: $0._id, _rev: $0._rev, _deleted: true, value: $0.value)
                    }
                    guard let bulkDelete = try? BulkDocuments(encoding: documentsToDelete) else {
                        return XCTFail("Failed to encode documents to delete")
                    }
                    // Bulk delete documents
                    database.bulk(documents: bulkDelete) { bulkResponse, error in
                        guard let bulkResponse = bulkResponse else {
                            return XCTFail("Failed to bulk delete documents from database, error: \(String(describing: error?.localizedDescription))")
                        }
                        
                        // Check if all documents were deleted successfully
                        guard (bulkResponse.reduce(true) { $0 && ($1.ok ?? false) }) == true else {
                            return XCTFail("Failed to bulk delete documents from database, error: Not all documents were deleted successfully")
                        }
                        
                        // Get all documents (there should be none)
                        database.retrieveAll() { bulkResponse, error in
                            if let error = error {
                                return XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
                            }
                            XCTAssert(bulkResponse?.rows.count == 0, "Failed to bulk delete documents from database, error: Not all documents were deleted")
                        }
                    }
                }
            }
        }
    }
}

struct BulkTest: Document {
    let _id: String?
    var _rev: String?
    var _deleted: Bool?
    let value: String
}
