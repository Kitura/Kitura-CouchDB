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

class UsersDBTests: CouchDBTest {
    
    static var allTests: [(String, (UsersDBTests) -> () throws -> Void)] {
        return [
            ("testUserDBTest", testUserDBTest)
        ]
    }
    
    func testUserDBTest() {
        setUpDatabase {
            let usersDatabase = self.couchDBClient.usersDatabase()
            self.delay{self.createUser(usersDatabase: usersDatabase)}
        }
    }
    
    func createUser(usersDatabase: UsersDatabase) {
        usersDatabase.getUser(name: "David") { (userDoc: DefaultRetrievedUserDocument?, error) in
            let rev = userDoc?._rev
            let newUser = DefaultNewUserDocument(name: "David", password: "password", roles: [], rev: rev)
            usersDatabase.createUser(document: newUser) { (response, error) in
                if let error = error {
                    return XCTFail("Failed to create new users: \(error)")
                }
                XCTAssertTrue(response?.ok ?? false)
                self.delay{self.createSession()}
            }
        }
    }
    
    func createSession() {
        couchDBClient.createSession(name: "David", password: "password") { (cookie, sessionInfo, error) in
            guard let cookie = cookie, let sessionInfo = sessionInfo else {
                return XCTFail("Did not receive cookie and info when creating session: \(String(describing: error))")
            }
            print("Created session for \(sessionInfo.name)")
            self.delay{self.getSession(cookie: cookie)}
        }
    }
    
    func getSession(cookie: String) {
        couchDBClient.getSession(cookie: cookie) { (sessionInfo, error) in
            guard let sessionInfo = sessionInfo else {
                return XCTFail("Failed to get session: \(String(describing: error))")
            }
            print("Got session for \(sessionInfo.userCtx.name)")
        }
    }
}
