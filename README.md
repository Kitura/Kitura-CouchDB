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

Kitura-CouchDB is a pure Swift client which allows Kitura applications to interact with a CouchDB database.

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

## Use Kitura-CouchDB locally

The CouchDBSample executable demonstrates how to create, read, update and delete documents within a CouchDB database in Swift.

1. [Download CouchDB](http://couchdb.apache.org/#download) and install.

2. Set up an admin username and password in CouchDB.

3. Create a database with the name `kitura_test_db`.

4. Clone this repository:

    ```bash
    git clone https://github.com/IBM-Swift/Kitura-CouchDB.git
    ```

5. Update the following code in `Sources\CouchDBSample\main.swift` with your admin username and password (the host will default to 127.0.0.1 and the port will default to 5984):

    ```swift
    let connProperties = ConnectionProperties(
        host: host,         // httpd address
        port: port,         // httpd port
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

    You will see informational messages such as "Successfully created the following JSON document in CouchDB:" for each of the operations (create, read, update and delete) performed on the `kitura_test_db` database.

## Example

For a more comprehensive example, you can follow the Kitura tutorial [Getting Started with Server-side Swift on raywenderlich.com](https://www.raywenderlich.com/180721/kitura-tutorial-getting-started-with-server-side-swift) that shows you how to create a backend API and then link this to a CouchDB instance running on your local machine.

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/Kitura-CouchDB/index.html).

## Community
We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Kitura-CouchDB/blob/master/LICENSE.txt).
