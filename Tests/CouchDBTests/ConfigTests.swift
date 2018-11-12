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

class ConfigTests: CouchDBTest {
    
    static var allTests: [(String, (ConfigTests) -> () throws -> Void)] {
        return [
            ("testConfigTest", testConfigTest)
        ]
    }
    
    func testConfigTest() {
        setUpDatabase {
            self.delay{self.setConfig()}
        }
    }
    
    func setConfig() {
        self.couchDBClient.setConfig(section: "log", key: "level", value: "debug") { (error) in
            if let error = error {
                XCTFail("Failed to set config: \(error)")
            }
            print("Log level set to debug")
            self.delay{self.getAllConfig()}
            self.delay{self.getConfigSection()}
            self.delay{self.getConfigKey()}
        }
    }
    
    func getAllConfig() {
        self.couchDBClient.getConfig { (config, error) in
            if let error = error {
                XCTFail("Failed to get all config: \(error)")
            }
            let logLevel = config?["log"]?["level"]
            XCTAssertEqual(logLevel, "debug")
            print("Got all config with debug set")
        }
    }
    
    func getConfigSection() {
        self.couchDBClient.getConfig(section: "log") { (config, error) in
            if let error = error {
                XCTFail("Failed to get config section: \(error)")
            }
            let logLevel = config?["level"]
            XCTAssertEqual(logLevel, "debug")
            print("Got config section with debug set")
        }
    }
    
    func getConfigKey() {
        self.couchDBClient.getConfig(section: "log", key: "level") { (config, error) in
            if let error = error {
                XCTFail("Failed to get config section: \(error)")
            }
            let logLevel = config
            XCTAssertEqual(logLevel, "debug")
            print("Got config section with debug set")
        }
    }
}
