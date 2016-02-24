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
import CouchDB

class TestDBLifecycle : XCTestCase {
	var allTests : [(String, () throws -> Void)] {
        return [
            ("dbLifecycle", dbLifecycle),
        ]
    }

    func dbLifecycle() {
    	let credentials = readCredentials()

    	// Connection properties for testing Cloudant or CouchDB instance
        let connProperties = ConnectionProperties(hostName: credentials.host,
            port: 80, secured: false,
            userName: credentials.username,
            password: credentials.password)
        
        // Create couchDBClient instance using conn properties
        let couchDBClient = CouchDBClient(connectionProperties: connProperties)
        print("Hostname is: \(couchDBClient.connProperties.hostName)")

        couchDBClient.createDB("test_db") {(db: Database?, error: NSError?) in
        	if let error = error {
        		XCTFail("DB creation error: \(error.code) \(error.localizedDescription)")
        	}
        	guard let db = db else {
        		XCTFail("Created database is nil")
        		return
        	}
        	print(">> Database successfully created")
        	couchDBClient.deleteDB(db) {(error: NSError?) in
        		if let error = error {
        			XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
        		}
        		print(">> Database successfully deleted")
        	}
        }
    }

    struct Credentials {
        let host:String
        let username:String
        let password:String
        init(host:String, username:String, password:String) {
            self.host = host
            self.username = username
            self.password = password
        }
    }

    func readCredentials() -> Credentials {
        // Read in credentials file
        let fstream = fopen("Tests/Sources/CouchDBTests/credentials.json", "r")
        XCTAssertNotNil(fstream, "Error opening credentials.json, try running from root directory")
        
        var credentialsString = ""
        while(true) {
            let c = fgetc(fstream)
            if c == -1 {
                break
            }
            credentialsString += String(Character(UnicodeScalar(UInt32(c))))
        }
        
        // Convert JSON string to NSData
        let credentialsData = credentialsString.bridge().dataUsingEncoding(NSUTF8StringEncoding)
        // Convert NSData to JSON object
        let credentialsJson = JSON(data: credentialsData!)
        
        guard let hostName = credentialsJson["host"].string,
        let userName = credentialsJson["username"].string,
        let password = credentialsJson["password"].string else {
            XCTFail("Error in credentials.json")
            exit(1)
        }
        print(">> Successfully read in credentials")
        return Credentials(host: hostName, username: userName, password: password)
    }

 }