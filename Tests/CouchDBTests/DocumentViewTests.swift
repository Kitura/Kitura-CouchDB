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

class DocumentViewTests: CouchDBTest {

    static var allTests: [(String, (DocumentViewTests) -> () throws -> Void)] {
        return [
                   ("testViewTest", testViewTest)
        ]
    }
    let documentId = "123456"

    func testViewTest() {
        setUpDatabase() {
            self.createDocument()
        }
    }

    //Create document closure
    func createDocument() {
        let myDoc = MyDocument(_id: documentId,
                                 _rev: nil,
                                 truncated: false,
                                 created_at: "Tue Aug 28 21:16:23 +0000 2012",
                                 favorited: false,
                                 value: "viewTest")

        database?.create(myDoc, callback: { (document: DocumentResponse?, error: NSError?) in
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
        let designDocument = DesignDocument(_id: "_design/\(name)",
                                            views: [
                                                "matching" : [
                                                    "map" : "function(doc) { emit(doc.value, doc); }"
                                                ]
                                            ])
        database?.createDesign(name, document: designDocument) { (document: DocumentResponse?, error: NSError?) in
            if let error = error {
                XCTFail("Error in creating document \(error.code) \(error.domain) \(error.userInfo)")
            } else {
                print(">> Successfully created the design.")
                self.readDocument()
            }
        }
    }
    
    //Read document
    func readDocument() {
        let key = "viewTest"
        
        database?.queryByView("matching", ofDesign: "test", usingParameters: [.keys([key])]) { (documents: AllDatabaseDocuments?, error: NSError?) in
            guard let documents = documents else {
                return XCTFail("Error in querying by view document \(String(describing: error?.code)) \(String(describing: error?.domain)) \(String(describing: error?.userInfo))")
            }
            guard let value = ((documents.rows[0])["value"] as? [String:Any])?["value"] as? String,
                let id = documents.rows[0]["id"] as? String
            else {
                return XCTFail("Error: Keys not found when reading document")
            }
            
            XCTAssertEqual(self.documentId, id, "Wrong documentId read from document")
            XCTAssertEqual(key, value, "Wrong value read from document")
            
            print(">> Successfully read the following JSON document: ")
            print(documents)
        }
    }
}
