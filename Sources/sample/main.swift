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

do {
  let couchDBClient = try CouchDBClientBuilder()
    .hostName("localhost")
    .port(9080)
    .databaseName("phoenix_db")
    .build()

  print("Hostname is: \(couchDBClient.connProperties.hostName)")

  print("YEAH")
  print("JSON data is: \(jsonData)")
  couchDBClient.test(json)
} catch CouchDBClientBuilder.Error.MissingRequiredParameters {
  print("Oops... missing parameters")
}

print("Sample program completed its execution.")
