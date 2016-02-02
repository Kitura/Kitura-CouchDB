//
//  Package.swift
//  PhoenixCouchDB
//
// @author Ira Rosen, Ricardo Olivieri
// Copyright © 2015 IBM. All rights reserved.
//

// Using atom with Swift:
// https://medium.com/@Aciid/hacking-atom-to-create-a-swift-ide-that-runs-on-linux-and-mac-c7d9520a0fac#.1bjuddaq2

import PackageDescription

// Dual pathing for O/S differences
#if os(Linux)
   let swiftyJsonUrl = "git@github.ibm.com:ibmswift/SwiftyJSON.git"
   let swiftyJsonVersion = 3
#else
   let swiftyJsonUrl = "https://github.com/SwiftyJSON/SwiftyJSON.git"
   let swiftyJsonVersion = 2
#endif

let package = Package(
    name: "PhoenixCouchDB",
    targets: [
        Target(
            name: "CouchDB",
            dependencies: []),
        Target(
            name: "CouchDBSample",
            dependencies: [.Target(name: "CouchDB")]),
    ],
    dependencies: [
      .Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 0),
      .Package(url: "git@github.ibm.com:ibmswift/PhoenixCurlHelpers.git", majorVersion: 1),
      .Package(url: "git@github.ibm.com:ibmswift/PhoenixHttpParserHelper.git", majorVersion: 1),
	    .Package(url: "git@github.ibm.com:ibmswift/PhoenixPcre2.git", majorVersion: 1),
      .Package(url: swiftyJsonUrl, majorVersion: swiftyJsonVersion)
    ]
)
