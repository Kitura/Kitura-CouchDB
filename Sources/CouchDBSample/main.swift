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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import SwiftyJSON
import CouchDB


print("Starting sample program...")

// Parse runtime args... this is just an interim solution
let args = Array(Process.arguments[1..<Process.arguments.count])
if args.count != 3 {
  print("Hostname, username and password are required as arguments!")
  exit(1)
}
let hostName = args[0]
let userName = args[1]
let password = args[2]

// Connection properties for testing Cloudant or CouchDB instance
let connProperties = ConnectionProperties(hostName: hostName,
  port: 80, secured: false,
  userName: userName,
  password: password)

let connPropertiesStr = connProperties.toString()
print("connPropertiesStr:\n\(connPropertiesStr)")

// Create couchDBClient instance using conn properties
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
print("Hostname is: \(couchDBClient.connProperties.hostName)")

// Create database instance to perform any document operations
let database = couchDBClient.database("phoenix_db")

// Document ID
let documentId = "123456"

// JSON document in string format
let jsonStr =
  "{" +
    "\"_id\": \"\(documentId)\"," +
    "\"coordinates\": null," +
    "\"truncated\": false," +
    "\"created_at\": \"Tue Aug 28 21:16:23 +0000 2012\"," +
    "\"favorited\": false," +
    "\"value\": \"value1\"" +
  "}"

// Convert JSON string to NSData
#if os(Linux)
let jsonData = jsonStr.bridge().dataUsingEncoding(NSUTF8StringEncoding)
#else
let jsonData = jsonStr.bridge().data(usingEncoding: NSUTF8StringEncoding)
#endif
// Convert NSData to JSON object
let json = JSON(data: jsonData!)

func chainer(document: JSON?, next: (revisionNumber: String) -> Void) {
  if let revisionNumber = document?["rev"].string {
    print("revisionNumber is \(revisionNumber)")
    next(revisionNumber: revisionNumber)
  } else if let revisionNumber = document?["_rev"].string {
    print("revisionNumber is \(revisionNumber)")
    next(revisionNumber: revisionNumber)
  } else {
    print(">> Oops something went wrong... could not get revisionNumber!")
  }
}

//Delete document
func deleteDocument(revisionNumber: String) {
  database.delete(documentId, rev: revisionNumber, failOnNotFound: false,
    callback: { (error: NSError?) in
        if error != nil {
            print(">> Oops something went wrong; could not delete document.")
            print(error!.code)
            print(error!.domain)
            print(error!.userInfo)
        } else {
            print(">> Successfully deleted the JSON document with ID \(documentId) from CouchDB.")
        }
  })
}

//Update document
func updateDocument(revisionNumber: String) {
  //var json = JSON(data: jsonData!)
  //json["value"] = "value2"
  database.update(documentId, rev: revisionNumber, document: json,
    callback: { (rev: String?, document: JSON?, error: NSError?) in
        if error != nil {
            print(">> Oops something went wrong; could not update document.")
            print(error!.code)
            print(error!.domain)
            print(error!.userInfo)
        } else {
            print(">> Successfully updated the JSON document with ID" +
                "\(documentId) in CouchDB:\n\t\(document)")
            chainer(document, next: deleteDocument)
        }
  })
}

//Read document
func readDocument() {
  database.retrieve(documentId, callback: { (document: JSON?, error: NSError?) in
    if error != nil {
      print("Oops something went wrong; could not read document.")
      print(error!.code)
      print(error!.domain)
      print(error!.userInfo)
    } else {
      print(">> Successfully read the following JSON document with ID " +
            "\(documentId) from CouchDB:\n\t\(document)")
      chainer(document, next: updateDocument)
    }
  })
}

//Create document closure
func createDocument() {
  database.create(json, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
    if error != nil {
      print(">> Oops something went wrong; could not persist document.")
      print(error!.code)
      print(error!.domain)
      print(error!.userInfo)
    } else {
      print(">> Successfully created the following JSON document in CouchDB:\n\t\(document)")
      readDocument()
    }
  })
}

// Start tests...
createDocument()

print("Sample program completed its execution.")
