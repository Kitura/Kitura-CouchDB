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
import LoggerAPI
import HeliumLogger

Log.logger = HeliumLogger()
Log.info("Starting sample program...")

// Parse runtime args...
let args = Array(Process.arguments[1..<Process.arguments.count])

if args.count > 5 {
    print("Too many arguments!")
    exit(1)
}

if args.count == 4 {
    print("username specified without password")
    exit(1)
}

if args.count == 1  &&  args[0] == "--help" {
    print("Usage:")
    print("   .build/debug/CouchDBSample [host [port [secure/unsecure [username password]]]]")
    exit(0)
}

let host = args.count > 0 ? args[0] : "127.0.0.1" /* localhost */
let port = args.count > 1 ? Int16(args[1]) ?? 5984 : 5984
let secured = args.count > 2 ? (args[2].lowercased() == "secure") : false
let username: String? = args.count == 5 ? args[3] : nil
let password: String? = args.count == 5 ? args[4] : nil

// Connection properties for testing Cloudant or CouchDB instance
let connProperties = ConnectionProperties(
    host: host,         // httpd address
    port: port,         // httpd port
    secured: secured,   // https or http
    username: username, // username
    password: password  // password
)

Log.info("Connection Properties:\n\(connProperties)")

// Create couchDBClient instance using conn properties
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
Log.info("Hostname is: \(couchDBClient.connProperties.host)")

// Create database instance to perform any document operations
let database = couchDBClient.database("kitura_test_db")

// Document ID
let documentId = "123456"

#if os(Linux)
typealias valuetype = Any
#else
typealias valuetype = AnyObject
#endif

// JSON document in string format
let jsonDict: [String: valuetype] = [
    "_id": documentId,
    "truncated": false,
    "created_at": "Tue Aug 28 21:16:23 +0000 2012",
    "favorited": false,
    "value": "value1"
]
let json = JSON(jsonDict)


// MARK: Chainer

func chainer(_ document: JSON?, next: (revisionNumber: String) -> Void) {
    if let revisionNumber = document?["rev"].string {
        Log.info("revisionNumber is \(revisionNumber)")
        next(revisionNumber: revisionNumber)
    } else if let revisionNumber = document?["_rev"].string {
        Log.info("revisionNumber is \(revisionNumber)")
        next(revisionNumber: revisionNumber)
    } else {
        Log.error(">> Oops something went wrong... could not get revisionNumber!")
    }
}


// MARK: Create document

func createDocument() {
    database.create(json, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
        if let error = error {
            Log.error(">> Oops something went wrong; could not persist document.")
            Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
        } else {
            Log.info(">> Successfully created the following JSON document in CouchDB:\n\t\(document)")
            readDocument()
        }
    })
}


// MARK: Read document

func readDocument() {
    database.retrieve(documentId, callback: { (document: JSON?, error: NSError?) in
        if let error = error {
            Log.error("Oops something went wrong; could not read document.")
            Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
        } else {
            Log.info(">> Successfully read the following JSON document with ID " +
                "\(documentId) from CouchDB:\n\t\(document)")
            chainer(document, next: updateDocument)
        }
    })
}


// MARK: Update document

func updateDocument(revisionNumber: String) {
    //var json = JSON(data: jsonData!)
    //json["value"] = "value2"
    database.update(documentId, rev: revisionNumber, document: json,
        callback: { (rev: String?, document: JSON?, error: NSError?) in
            if let error = error {
                Log.error(">> Oops something went wrong; could not update document.")
                Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
            } else {
                Log.info(">> Successfully updated the JSON document with ID" +
                    "\(documentId) in CouchDB:\n\t\(document)")
                chainer(document, next: deleteDocument)
            }
    })
}


// MARK: Delete document

func deleteDocument(revisionNumber: String) {
    database.delete(documentId, rev: revisionNumber, failOnNotFound: false,
        callback: { (error: NSError?) in
            if let error = error {
                Log.error(">> Oops something went wrong; could not delete document.")
                Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
            } else {
                Log.info(">> Successfully deleted the JSON document with ID \(documentId) from CouchDB.")
            }
    })
}


// Start tests...
createDocument()

Log.info("Sample program completed its execution.")
