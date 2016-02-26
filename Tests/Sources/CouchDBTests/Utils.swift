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

class Utils {

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

    static func readCredentials() -> Credentials {
        // Read in credentials file
        let fstream = fopen("Tests/Sources/CouchDBTests/credentials.json", "r")
        XCTAssertNotNil(fstream, "Error opening credentials.json. Please try running from root directory.")

        var credentialsString = ""
        while(true) {
            let char = fgetc(fstream)
            // EOF?
            if char == -1 {
                break
            }
            credentialsString += String(Character(UnicodeScalar(UInt32(char))))
        }

        // Convert JSON string to NSData
        let credentialsData = credentialsString.bridge().dataUsingEncoding(NSUTF8StringEncoding)
        // Convert NSData to JSON object
        let credentialsJson = JSON(data: credentialsData!)

        guard
          let hostName = credentialsJson["host"].string,
          let userName = credentialsJson["username"].string,
          let password = credentialsJson["password"].string
        else {
            XCTFail("Error in credentials.json.")
            exit(1)
        }

        print(">> Successfully read in credentials.")
        return Credentials(host: hostName, username: userName, password: password)
    }
}
