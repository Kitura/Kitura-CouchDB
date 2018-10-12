/**
* Copyright IBM Corporation 2016, 2018
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
import Dispatch

@testable import CouchDB

class CouchDBTest: XCTestCase {

	// MARK: - Database connection properties

    // The database name should be defined in an environment variable TESTDB_NAME
    // in Travis, to allow each Travis build to use a separate database.
    let dbName = ProcessInfo.processInfo.environment["TESTDB_NAME"] ?? "Error-TESTDB_NAME-not-set"

    let couchDBClient: CouchDBClient! = {
        let credentials = Utils.readCredentials()

        // Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(host: credentials.host,
                                                  port: credentials.port,
                                                  secured: true,
                                                  username: credentials.username,
                                                  password: credentials.password)

        // Create couchDBClient instance using connection properties
        let client = CouchDBClient(connectionProperties: connProperties)

        print("Hostname is: \(client.connProperties.host)")

        return client
    }()

    var database: Database?

    /// Drop the test database, if it exists.
    ///
    func dropDatabaseIfExists(completion: @escaping () -> Void) {
        // Check if DB exists
       delay {
            self.couchDBClient.dbExists(self.dbName) { exists, error in
                if  error != nil {
                    XCTFail("Failed checking existence of database \(self.dbName). Error=\(error!.localizedDescription)")
                } else {
                    if  exists {
                        self.dropDatabase(completion)
                    }
                }
            }
        }
    }

    // setting up  the database
    func setUpDatabase(isSetUpCompleted: @escaping () -> Void) -> Void {
        self.dropDatabaseIfExists() {
            self.createDatabase() {
                isSetUpCompleted()
            }
        }
    }

    /// Create the test database, failing the test if it already exists, or if there
    /// is a connectivity error.
    ///

    fileprivate func createDatabase( _ handler: @escaping () -> Void)  -> Void {
        delay {
            self.couchDBClient.createDB(self.dbName) { database, error in
                if let error = error {
                    XCTFail("DB creation error: \(error.code) \(error.localizedDescription)")
                    return
                }
                if database == nil {
                    XCTFail("Created database is nil")
                    return
                }
                print("Database \"\(self.dbName)\" successfully created")
                self.database = database
                handler()
            }
        }
    }

    /// Drop the test database, failing the test if it does not exist, or if there
    /// is a connectivity error.
    ///
    fileprivate func dropDatabase(_ handler: @escaping () -> Void) -> Void {
        // Retrieve and delete test database
        delay {
            self.couchDBClient.deleteDB(self.dbName) { error in
                if let error = error {
                    XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
                    return
                }
                print("Database \"\(self.dbName)\" successfully deleted")
                handler()
            }

        }
    }

    /// Delay an action by a specified amount of time (default 1 second). The purpose
    /// of delaying actions in CouchDB tests is to avoid exceeding the API limit for
    /// the test database provider while running multiple executions via Travis.
    ///
    func delay(time: Double = 1.0, _ work: @escaping () -> Void) {
        let start = DispatchSemaphore(value: 0)
        let end = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + time) {
            start.wait()
            work()
            end.signal()
        }
        start.signal()
        end.wait()
    }
}

