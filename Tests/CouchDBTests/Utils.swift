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
        let host: String
        let port: Int16
        let username: String?
        let password: String?
        init(host: String, port: Int16, username: String?, password: String?) {
            self.host = host
            self.port = port
            self.username = username
            self.password = password
        }
    }

    static func readCredentials() -> Credentials {
        // Read in credentials an Data
        let credentialsData: Data
        let sourceFileName = NSString(string: #file)
        let resourceFilePrefixRange: NSRange
        let lastSlash = sourceFileName.range(of: "/", options: .backwards)
        if  lastSlash.location != NSNotFound {
            resourceFilePrefixRange = NSMakeRange(0, lastSlash.location+1)
        } else {
            resourceFilePrefixRange = NSMakeRange(0, sourceFileName.length)
        }
        let fileNamePrefix = sourceFileName.substring(with: resourceFilePrefixRange)
        do {
            credentialsData = try Data(contentsOf: URL(fileURLWithPath: "\(fileNamePrefix)credentials.json"))
        } catch {
            XCTFail("Failed to read in the credentials.json file")
            exit(1)
        }
        // Convert NSData to JSON object
        let credentialsJson = JSON(data: credentialsData)

        guard
          let hostName = credentialsJson["host"].string,
          let port = credentialsJson["port"].int16
        else {
            XCTFail("Error in credentials.json.")
            exit(1)
        }
        let userName = credentialsJson["username"].string
        let password = credentialsJson["password"].string

        print(">> Successfully read in credentials.")
        return Credentials(host: hostName, port: port, username: userName, password: password)
    }
}
