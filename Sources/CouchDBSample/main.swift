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

import Foundation
import CouchDB

print("Starting sample program...")

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

let port: UInt16
if args.count > 1 {
    port = UInt16(args[1]) ?? 5984
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
    username: nil,      // admin username
    password: nil       // admin password
)

print("Connection Properties:\n\(connProperties)")

// Create couchDBClient instance using connection properties
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
print("Hostname is: \(couchDBClient.connProperties.host)")
var database: Database?

//// Document ID
let documentId = "123456"

struct MyDocument: Document {
    let _id: String?
    var _rev: String?
    let truncated: Bool
    let created_at: Date
    let favorited: Bool
    let value: String
}
var myDocument = MyDocument(_id: documentId,
                            _rev: nil,
                            truncated: false,
                            created_at: Date(),
                            favorited: false,
                            value: "value1")
// MARK: Chainer

func chainer(_ document: MyDocument?, next: (String) -> Void) {
    if let revisionNumber = document?._rev {
        print("revisionNumber is \(revisionNumber)")
        next(revisionNumber)
    } else {
        print(">> Oops something went wrong... could not get revisionNumber!")
    }
}

// Create database instance to perform any document operations
func initializeDatabase() {
    couchDBClient.retrieveDB("kitura_test_db") { (localDatabase, error) in
        if let localDatabase = localDatabase {
            database = localDatabase
            createDocument()
        } else {
            couchDBClient.createDB("kitura_test_db") { (localDatabase, error) in
                guard let localDatabase = localDatabase else {
                    print("Error initializing Database: \(String(describing: error))")
                    return
                }
                database = localDatabase
                createDocument()
            }
        }
    }
}

// MARK: Create document

func createDocument() {
    database?.create(myDocument) { (document, error) in
        if let error = error {
            print(">> Oops something went wrong; could not persist document.")
            print("Error: \(error.localizedDescription) Code: \(error.statusCode)")
        } else {
            print(">> Successfully created the following JSON document in CouchDB:\n\t\(String(describing: document))")
            readAllDocuments()
        }
    }
}

// MARK: Read all documents

func readAllDocuments() {
    database?.retrieveAll(includeDocuments: true) { documents, error in
        if let error = error {
            print("Oops something went wrong; could not read document.")
            print("Error: \(error.description) Code: \(error.statusCode)")
        } else {
            print(">> Successfully read \(String(describing: documents?.total_rows)) documents from database")
            let typedDocuments = documents?.decodeDocuments(ofType: MyDocument.self)
            print(">> Successfully read \(String(describing: typedDocuments?.count)) documents from database")
            readDocument()
        }
    }
}

// MARK: Read document

func readDocument() {
    database?.retrieve(documentId) { (document: MyDocument?, error: CouchDBError?) in
        if let error = error {
            print("Oops something went wrong; could not read document.")
            print("Error: \(error.description) Code: \(error.statusCode)")
        } else {
            print(">> Successfully read the following JSON document with ID " +
                "\(documentId) from CouchDB:\n\t\(String(describing: document))")
            chainer(document, next: updateDocument)
        }
    }
}


// MARK: Update document

func updateDocument(revisionNumber: String) {
    database?.update(documentId, rev: revisionNumber, document: myDocument) { (response, error) in
        if let error = error {
            print(">> Oops something went wrong; could not update document.")
            print("Error: \(error.description) Code: \(error.statusCode)")
        } else {
            myDocument._rev = response?.rev
            print(">> Successfully updated the JSON document with ID" +
                "\(documentId) in CouchDB:\n\t\(String(describing: response))")
            chainer(myDocument, next: deleteDocument)
        }
    }
}


// MARK: Delete document

func deleteDocument(revisionNumber: String) {
    database?.delete(documentId, rev: revisionNumber) { (error) in
        if let error = error {
            print(">> Oops something went wrong; could not delete document.")
            print("Error: \(error.description) Code: \(error.statusCode)")
        } else {
            print(">> Successfully deleted the JSON document with ID \(documentId) from CouchDB.")
        }
    }
}

// Start tests...
initializeDatabase()

print("Sample program completed its execution.")
