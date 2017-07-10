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
let args = Array(CommandLine.arguments[1..<CommandLine.arguments.count])

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

// The following assignments for now can't be collapsed to simple statements with a tertiary (?:)
// operator due to the bug in XCode 8.3 code coverage reported here https://bugs.swift.org/browse/SR-4453

let host: String
if args.count > 0 {
    host = args[0]
}
else {
    host = "127.0.0.1" /* localhost */
}

let port: Int16
if args.count > 1 {
    port = Int16(args[1]) ?? 5984
}
else {
    port = 5984
}

let secured: Bool
if args.count > 2 {
    secured = (args[2].lowercased() == "secure")
}
else {
    secured = false
}

let username: String?
let password: String? 
if args.count == 5 {
    username = args[3]
    password = args[4]
}
else {
    username = nil
    password = nil
}

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
#if os(Linux)
let documentId = "123456"
#else
let documentId = "123456" as NSString
#endif

#if os(Linux)
typealias valuetype = Any
#else
typealias valuetype = AnyObject
#endif

// JSON document in string format
let jsonDict: [String: valuetype] = [
    "_id": documentId,
    "truncated": false as valuetype,
    "created_at": "Tue Aug 28 21:16:23 +0000 2012" as valuetype,
    "favorited": false as valuetype,
    "value": "value1" as valuetype
]
#if os(Linux)
let json = JSON(jsonDict)
#else
let json = JSON(jsonDict as AnyObject)
#endif


// MARK: Chainer

func chainer(_ document: JSON?, next: (String) -> Void) {
    if let revisionNumber = document?["rev"].string {
        Log.info("revisionNumber is \(revisionNumber)")
        next(revisionNumber)
    } else if let revisionNumber = document?["_rev"].string {
        Log.info("revisionNumber is \(revisionNumber)")
        next(revisionNumber)
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
            Log.info(">> Successfully created the following JSON document in CouchDB:\n\t\(String(describing: document))")
            readDocument()
        }
    })
}


// MARK: Read document

func readDocument() {
    database.retrieve(documentId as String, callback: { (document: JSON?, error: NSError?) in
        if let error = error {
            Log.error("Oops something went wrong; could not read document.")
            Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
        } else {
            Log.info(">> Successfully read the following JSON document with ID " +
                "\(documentId) from CouchDB:\n\t\(String(describing: document))")
            chainer(document, next: updateDocument)
        }
    })
}


// MARK: Update document

func updateDocument(revisionNumber: String) {
    //var json = JSON(data: jsonData!)
    //json["value"] = "value2"
    database.update(documentId as String, rev: revisionNumber, document: json,
        callback: { (rev: String?, document: JSON?, error: NSError?) in
            if let error = error {
                Log.error(">> Oops something went wrong; could not update document.")
                Log.error("Error: \(error.localizedDescription) Code: \(error.code)")
            } else {
                Log.info(">> Successfully updated the JSON document with ID" +
                    "\(documentId) in CouchDB:\n\t\(String(describing: document))")
                chainer(document, next: deleteDocument)
            }
    })
}


// MARK: Delete document

func deleteDocument(revisionNumber: String) {
    database.delete(documentId as String, rev: revisionNumber, failOnNotFound: false,
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
