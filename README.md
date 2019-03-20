<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/Kitura-CouchDB/index.html">
    <img src="https://img.shields.io/badge/apidoc-KituraCouchDB-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Kitura-CouchDB">
    <img src="https://travis-ci.org/IBM-Swift/Kitura-CouchDB.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# Kitura-CouchDB

Kitura-CouchDB is a pure Swift client which allows Kitura applications to interact with a CouchDB or Cloudant database.

## Usage

#### Add dependencies

Add the `Kitura-CouchDB` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-CouchDB` [release](https://github.com/IBM-Swift/Kitura-CouchDB/releases).

```swift
.package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", from: "x.x.x")
```

Add `CouchDB` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["CouchDB"]),
```

#### Import package

```swift
import CouchDB
```

## Run Kitura-CouchDB Sample

To run the CouchDB Sample, you must set up and connect to a local CouchDB database by following the steps below:

1. [Download and install CouchDB.](http://couchdb.apache.org/#download)

2. Set up an admin username and password in CouchDB.

3. Create a database with the name `kitura_test_db`.

4. Clone this repository:

    ```bash
    git clone https://github.com/IBM-Swift/Kitura-CouchDB.git
    ```

5. Update the following code in `Sources\CouchDBSample\main.swift` with your admin username and password (the host will default to 127.0.0.1 and the port will default to 5984):

    ```swift
    let connProperties = ConnectionProperties(
        host: host,         // http address
        port: port,         // http port
        secured: secured,   // https or http
        username: nil,      // admin username
        password: nil       // admin password
    )
    ```

6. Open a Terminal window, change into the `Kitura-CouchDB` folder and run `swift build`:

    ```bash
    swift build
    ```

7. Run the CouchDBSample executable:

    ```bash
    .build/debug/CouchDBSample
    ```

    You should see informational messages such as "Successfully created the following JSON document in CouchDB:" for each of the operations (create, read, update and delete) performed on the `kitura_test_db` database.

## API Documentation

#### Document

CouchDB is a NoSQL database for storing documents. A `Document` is any structure that can be represented as JSON and contains `_id` and `_rev` fields.  
 - The `_id` field is the unique identifier for the document. If it is not set, a random UUID will be assigned for the document.  
 - The `_rev` field is the revision of the document. It is returned when you make requests and is used to prevent conflicts from multiple users updating the same document.  

To define a CouchDB document, create a Swift object and make it conform to the `Document` protocol:
 ```swift
 struct MyDocument: Document {
    let _id: String?
    var _rev: String?
    var value: String
}
 ```

#### CouchDBClient

The `CouchDBClient` represents a connection to a CouchDB server. It is initialized with your `ConnectionProperties` and handles the creation, retrieval and deletion of CouchDB databases.

```swift
// Define ConnectionProperties
let conProperties = ConnectionProperties(
    host: "127.0.0.1",              // http address
    port: 5984,                     // http port
    secured: false,                 // https or http
    username: "<CouchDB-username>", // admin username
    password: "<CouchDB-password>"  // admin password
)
// Initialize CouchDBClient
let couchDBClient = CouchDBClient(connectionProperties: conProperties)
```
- Create a new database

```swift
couchDBClient.createDB("NewDB") { (database, error) in
    if let database = database {
        // Use database
    }
}
```
- Get an existing database

```swift
couchDBClient.retrieveDB("ExistingDB") { (database, error) in
    if let database = database {
        // Use database
    }
}
```
- Delete a database

```swift
couchDBClient.deleteDB("ExistingDB") { (error) in
    if let error = error {
        // Handle the error
    }
}
```

#### Database

The `Database` class is used to make HTTP requests to the corresponding CouchDB database. This class can make CRUD (Create, Retrieve, Update, Delete) requests for:

- A single CouchDB `Document`
- An array of CouchDB documents
- A CouchDB `DesignDocument`
- A `Document` attachment

The following code demonstrates the CRUD operations for a single `Document`:  

```swift
var myDocument = MyDocument(_id: "Kitura", _rev: nil, value: "Hello World")
```
- Create a Document:  

```swift
database.create(myDocument) { (response, error) in
    if let response = response {
        print("Document: \(response.id), created with rev: \(response.rev)")
    }
}
```
- Retrieve a Document:  

```swift
database.retrieve("Kitura") { (document: MyDocument?, error: CouchDBError?) in
    if let document = document {
        print("Retrieved document with value: \(document.value)")
    }
}
```
- Update a Document:  

```swift
myDocument.value = "New Value"
database.update("Kitura", rev: "<latest_rev>", document: myDocument) { (response, error) in
    if let response = response {
        print("Document: \(response.id), updated")
    }
}
```
- Delete a Document:  

```swift
database.delete("Kitura", rev: "<latest_rev>") { (error) in
    if error == nil {
        print("Document successfully deleted")
    }
}
```

For more information visit our [API reference](https://ibm-swift.github.io/Kitura-CouchDB/index.html).

## Community
We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Kitura-CouchDB/blob/master/LICENSE.txt).
