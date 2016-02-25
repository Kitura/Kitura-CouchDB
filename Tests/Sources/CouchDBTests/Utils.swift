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