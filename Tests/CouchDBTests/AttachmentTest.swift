/**
 * Copyright IBM Corporation 2018
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

class AttachmentTests: CouchDBTest {
    
    static var allTests: [(String, (AttachmentTests) -> () throws -> Void)] {
        return [
            ("testAttachmentTest", testAttachmentTest)
        ]
    }
    
    let myDocument = TypeADocument(_id: "123456",
                                   _rev: nil,
                                   truncated: false,
                                   created_at: "Tue Aug 28 21:16:23 +0000 2012",
                                   favorited: false,
                                   value: "value1")
    
    func testAttachmentTest() {
        setUpDatabase {
            self.delay{self.createDocument(document: self.myDocument)}
        }
    }
    
    //Create document closure
    func createDocument<D: Document>(document: D) {
        database?.create(document, callback: { (response: DocumentResponse?, error) in
            guard let response = response else {
                return XCTFail("Error in creating document \(String(describing: error?.description))")
            }
            print("Created document")
            self.delay{self.addAttachment(id: response.id, rev: response.rev)}
        })
    }
    
    func addAttachment(id: String, rev: String) {
        let attachmentData = "Hello World".data(using: .utf8)!
        database?.createAttachment(id, docRevison: rev, attachmentName: "myAttachment", attachmentData: attachmentData, contentType: "text/*", callback: { (response, error) in
            guard let response = response else {
                return XCTFail("Error creating attachment: \(String(describing: error))")
            }
            print("Added Attachment")
            self.delay{self.retrieveAttachment(id: response.id, name: "myAttachment", rev: response.rev)}
        })
    }
    
    func retrieveAttachment(id: String, name: String, rev: String) {
        database?.retrieveAttachment(id, attachmentName: name, callback: { (data, contentType, error) in
            XCTAssertEqual(contentType, "text/*")
            guard let data = data else {
                return XCTFail("Error retrieving attachment: \(String(describing: error))")
            }
            let attachmentString = String(data: data, encoding: .utf8)
            XCTAssertEqual(attachmentString, "Hello World")
            print("Retrieved Attachment")
            self.delay{self.deleteAttachment(id: id, name: name, rev: rev)}
        })
    }
    
    func deleteAttachment(id: String, name: String, rev: String) {
        database?.deleteAttachment(id, docRevison: rev, attachmentName: name, callback: { (error) in
            if let error = error {
                return XCTFail("Error deleting attachment: \(String(describing: error))")
            }
            print("Deleted attachment")
            self.delay{
                self.database?.retrieveAttachment(id, attachmentName: name, callback: { (data, contentType, error) in
                    guard data == nil, contentType == nil else {
                        return XCTFail("Attachment wasn't deleted)")
                    }
                    XCTAssertEqual(error?.statusCode, 404)
                })
            }
        })
    }
}
