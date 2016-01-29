/*
* References
//http://guide.couchdb.org/draft/security.html#authentication
//http://curl.haxx.se/docs/manual.html
// curl http://name:passwd@machine.domain/full/path/to/file
//https://wiki.apache.org/couchdb/HTTP_Document_API
*
*/
import Foundation
import CouchDB
import SwiftyJSON

print("Starting sample program...")

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

let connProperties = ConnectionProperties(userName: "fee33f3a-cdbc-4c9b-bf9a-f1541ee68c06-bluemix",
  password: "2e2c5dc953727c763ff19b1ff399bd8b97ef5e3d7c249e55879eb849deafe374", secured: false, databaseName: "phoenix_db")

let connPropertiesStr = connProperties.toString()
print("connPropertiesStr:\n\(connPropertiesStr)")

let couchDBClient = CouchDBClient(connectionProperties: connProperties)

print("Hostname is: \(couchDBClient.connProperties.hostName)")
print("JSON data is: \(jsonData)")
couchDBClient.test2(json)

print("Sample program completed its execution.")
