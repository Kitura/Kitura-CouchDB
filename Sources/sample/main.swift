//
//  main.swift
//  PhoenixCouchDB
//  Sample code
//
//  Authors: Ricardo Olivieri
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import CouchDB
import SwiftyJSON

print("Starting sample program...")

// Connection properties for test Cloudant instance
let connProperties = ConnectionProperties(hostName: "fee33f3a-cdbc-4c9b-bf9a-f1541ee68c06-bluemix.cloudant.com",
  port: 80, secured: false,
  userName: "fee33f3a-cdbc-4c9b-bf9a-f1541ee68c06-bluemix",
  password: "2e2c5dc953727c763ff19b1ff399bd8b97ef5e3d7c249e55879eb849deafe374")

let connPropertiesStr = connProperties.toString()
print("connPropertiesStr:\n\(connPropertiesStr)")

// Create couchDBClient instance using conn properties
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
print("Hostname is: \(couchDBClient.connProperties.hostName)")

// Create database instance to perform any document operations
let database = couchDBClient.database("phoenix_db")

// Read sample document
database.retrieve("93868ba2bbea73154974a72eb3ef7144", connProperties: connProperties, callback: { (document: JSON?, error: NSError?) in
  if (error != nil) {
    print("Oops something went wrong; could not read document.")
    print(error!.code)
    print(error!.domain)
    print(error!.userInfo)
  } else {
    print("Here is the JSON document returned from Cloudant:\n\t\(document)")
  }
})

// Write document
// JSON string
let jsonStr =
  "{" +
    "\"coordinates\": null," +
    "\"truncated\": false," +
    "\"created_at\": \"Tue Aug 28 21:16:23 +0000 2012\"," +
    "\"favorited\": false," +
    "\"id_str\": \"240558470661799936\"" +
  "}"

// Convert JSON string to NSData
let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding)
// Convert NSData to JSON object
let json = JSON(data: jsonData!)
database.create(json, connProperties: connProperties, callback: { (id: String?, rev:String?, document: JSON?, error: NSError?) in
  if (error != nil) {
    print("Oops something went wrong; could not persist document.")
    print(error!.code)
    print(error!.domain)
    print(error!.userInfo)
  } else {
    print("Here is the JSON document that we just wrote to Cloudant:\n\t\(document)")
  }
})

//Need tests for CouchDB
print("Sample program completed its execution.")
