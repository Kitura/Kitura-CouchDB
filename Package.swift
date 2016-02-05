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
    name: "Kitura-CouchDB",
    targets: [
        Target(
            name: "CouchDB",
            dependencies: []),
        Target(
            name: "CouchDBSample",
            dependencies: [.Target(name: "CouchDB")]),
    ],
    // Ideally, we should only need to specify Phoenix and SwiftyJSON
    // as dependencies. For now, due to what seems to be a defect in SPM,
    // we are specifying these other dependencies.
    dependencies: [
      .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-router.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-CurlHelpers.git", majorVersion: 1),
      .Package(url: "https://github.com/IBM-Swift/Kitura-HttpParserHelper.git", majorVersion: 1),
      .Package(url: swiftyJsonUrl, majorVersion: swiftyJsonVersion)
    ]
)
