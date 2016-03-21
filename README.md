# Kitura-CouchDB

[![Build Status](https://travis-ci.org/IBM-Swift/Kitura-CouchDB.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-CouchDB)
[![Build Status](https://travis-ci.org/IBM-Swift/Kitura-CouchDB.svg?branch=develop)](https://travis-ci.org/IBM-Swift/Kitura-CouchDB)

***CouchDB library for [Kitura](https://github.com/IBM-Swift/Kitura)***

This library allows Kitura applications to interact with a CouchDB database.

Depends on [Kitura-router](https://github.com/IBM-Swift/Kitura-router).

## Build CouchDBSample:

1. [Download CouchDB](http://couchdb.apache.org/#download) and install.

2. Set up an admin username and password in CouchDB.

3. Create a database with the name `kitura_test_db`.

4. Update the following code in `main.swift` with your admin username and password:

	```swift
	let connProperties = ConnectionProperties(
    	host: "127.0.0.1",  // httpd address
    	port: 5984,         // httpd port
    	secured: false,     // https or http
    	username: nil,      // admin username
    	password: nil       // admin password
	)
	```

5. Open a Terminal window to the `Kitura-CouchDB` folder and run `make`:

	```bash
	make
	```

6. Run the CouchDBSample executable:

	```bash
	.build/debug/CouchDBSample
	```

## Usage:

(Todo)
