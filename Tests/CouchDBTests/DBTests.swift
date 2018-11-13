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

import Foundation

@testable import CouchDB

class DBTests: CouchDBTest {

    static var allTests: [(String, (DBTests) -> () throws -> Void)] {
        return [
            ("testDB", testDB),
        ]
    }
    
    /// Test that the database can be created and deleted.
    func testDB() {
        setUpDatabase() {
            self.couchDBClient?.deleteDB(self.dbName) {(error: NSError?) in
                if let error = error {
                    XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
                }
                print(">> Database successfully deleted ")

                self.couchDBClient?.createDB(self.dbName) {(db: Database?, error: NSError?) in
                    if let error = error {
                        XCTFail("DB creation error: \(error.code) \(error.localizedDescription)")
                    }

                    guard let db = db else {
                        XCTFail("Created database is nil")
                        return
                    }

                    print(">> Database successfully created \(db.name)")
                }
            }

        }

    }

}
