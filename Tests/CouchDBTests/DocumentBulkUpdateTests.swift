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

import XCTest

#if os(Linux)
	import Glibc
#else
	import Darwin
#endif

import Foundation
import SwiftyJSON

@testable import CouchDB

class DocumentBulkUpdateTests: XCTestCase {

	// Add an additional class variable holding all tests for Linux compatibility
	static var allTests: [(String, (DocumentBulkUpdateTests) -> () throws -> Void)] {
		return [
			("testBulkInsert", testBulkInsert),
			("testBulkUpdate", testBulkUpdate),
			("testBulkDelete", testBulkDelete)
		]
	}

	// To enable running Linux and OSX tests in parallel
#if os(Linux)
	let dbName = "test_db_linux"
#else
	let dbName = "test_db_db"
#endif

	// MARK: - Database connection properties

	static let dbSecuredConnection = true

	let couchDBClient: CouchDBClient! = {
		let credentials = Utils.readCredentials()

		// Connection properties for testing Cloudant or CouchDB instance
		let connProperties = ConnectionProperties(host: credentials.host,
		                                          port: credentials.port,
		                                          secured: dbSecuredConnection,
		                                          username: credentials.username,
		                                          password: credentials.password)

		// Create couchDBClient instance using connection properties
		let client = CouchDBClient(connectionProperties: connProperties)

		print("Hostname is: \(client.connProperties.host)")

		return client
	}()

	var database: Database?

	// MARK: - Database test objects

	let json1 = JSON(["_id": "1234567",
	                  "type": "user",
	                  "firstName": "John",
	                  "lastName": "Doe",
	                  "birthdate": "1985-01-23"])
	let json2 = JSON(["_id": "8901234",
	                  "type": "user",
	                  "firstName": "Mike",
	                  "lastName": "Wazowski",
	                  "birthdate": "1981-09-04"])
	let json3 = JSON(["_id": "5678901",
	                  "type": "address",
	                  "name": "139 Edgefield St. Honolulu, HI 96815",
	                  "country": "United States",
	                  "city": "Honolulu",
	                  "latitude": 21.319820,
	                  "longitude": -157.865501])
	let json4 = JSON(["_id": "2345678",
	                  "type": "address",
	                  "name": "79 Pumpkin Hill Road Monstropolis, MN 37803",
	                  "country": "United States",
	                  "city": "Monstropolis",
	                  "latitude": 44.961098,
	                  "longitude": -93.176732])
	let json5 = JSON(["_id": "9012345",
	                  "type": "userAddress",
	                  "userId": "1234567",
	                  "addressId": "5678901"])
	let json6 = JSON(["_id": "6789012",
	                  "type": "userAddress",
	                  "userId": "8901234",
	                  "addressId": "2345678"])

	// MARK: - Initializers and test set-up and tear-down

	override func setUp() {

		// Create test database
		couchDBClient.createDB(dbName) { database, error in
			if let error = error {
				XCTFail("DB creation error: \(error.code) \(error.localizedDescription)")
				return
			}

			if database == nil {
				XCTFail("Created database is nil")
				return
			}

			print("Database \"\(self.dbName)\" successfully created")

			// Assign data base
			self.database = database
		}
	}

	override func tearDown() {

		// Retrieve and delete test database
		couchDBClient.deleteDB(dbName) { error in
			if let error = error {
				XCTFail("DB deletion error: \(error.code) \(error.localizedDescription)")
				return
			}

			print("Database \"\(self.dbName)\" successfully deleted")
		}
	}

	// MARK: - Xcode tests

	func testBulkInsert() {
		guard let database = database else {
			XCTFail("Failed to retrieve database")
			return
		}

		let documents = [json1, json2, json3, json4, json5, json6]

		// Bulk insert documents
		database.bulk(documents: documents) { json, error in
			if let error = error {
				XCTFail("Failed to bulk insert documents into database, error: \(error.localizedDescription)")
				return
			}

			guard let jsonArray = json?.array else {
				XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
				return
			}

			XCTAssert(jsonArray.count == documents.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

			// Get all documents and compare their number to match the inserted number of documents
			database.retrieveAll() { json, error in
				if let error = error {
					XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
					return
				}

				guard let jsonArray = json?["rows"].array else {
					XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
					return
				}

				XCTAssert(jsonArray.count == documents.count, "Incorrect number of documents retrieved, error: Couldn't insert all documents")
			}
		}
	}

	func testBulkUpdate() {
		guard let database = database else {
			XCTFail("Failed to retrieve database")
			return
		}

		let documentsToInsert = [json1, json3, json5]
		let documentsToUpdate = [json2, json4, json6]

		// Bulk insert documents
		database.bulk(documents: documentsToInsert) { json, error in
			if let error = error {
				XCTFail("Failed to bulk insert documents into database, error: \(error.localizedDescription)")
				return
			}

			guard let jsonArray = json?.array else {
				XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
				return
			}

			XCTAssert(jsonArray.count == documentsToInsert.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

			// Assign same ID and REV numbers to documents to update
			let documentsToUpdate = documentsToUpdate.enumerated().map {
				var doc = $1.dictionaryValue

				doc["_id"] = jsonArray[$0]["id"]
				doc["_rev"] = jsonArray[$0]["rev"]

				return JSON(doc)
			} as [JSON]

			// Bulk update documents
			database.bulk(documents: documentsToUpdate) { json, error in
				if let error = error {
					XCTFail("Failed to bulk update documents from database, error: \(error.localizedDescription)")
					return
				}

				guard let jsonArray = json?.array else {
					XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
					return
				}

				// Check if all documents were updated successfully
				let success = jsonArray.reduce(true) { $0 && ($1["ok"].bool ?? false) }

				guard success == true else {
					XCTFail("Failed to bulk update documents from database, error: Not all documents were updated successfully")
					return
				}

				// Get all documents and compare their contents to match the updated documents
				database.retrieveAll(includeDocuments: true) { json, error in
					if let error = error {
						XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
						return
					}

					guard let jsonArray = json?["rows"].array else {
						XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
						return
					}

					// Check if all retrieved documents match the updated documents
					let success = jsonArray.reduce(true) { result, doc1 in

						// Get document with the same ID as this one
						guard let doc2 = (documentsToUpdate.first() { $0["_id"].string == doc1["id"].string }) else {
							return false
						}

						// Loop through all keys and values in document 1 and compare them to document 2
						var comparisonResult = true
						doc1["doc"].forEach() {

							// Ignore REV field since it is modified after updating the documents
							if $0 != "_rev" {
								comparisonResult = comparisonResult && ($1 == doc2[$0])
							}
						}
						return result && comparisonResult
					}

					XCTAssert(success, "Failed to bulk update documents from database, error: Updated documents do not match to the retrieved ones")
				}
			}
		}
	}

	func testBulkDelete() {
		guard let database = database else {
			XCTFail("Failed to retrieve database")
			return
		}

		let documents = [json4, json6, json5, json1, json3, json2]

		// Bulk insert documents
		database.bulk(documents: documents) { json, error in
			if let error = error {
				XCTFail("Failed to bulk insert documents into database, error: \(error.localizedDescription)")
				return
			}

			guard let jsonArray = json?.array else {
				XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
				return
			}

			XCTAssert(jsonArray.count == documents.count, "Incorrect number of documents inserted, error: Couldn't insert all documents")

			// Get all documents and build the payload sent for bulk deletion
			database.retrieveAll() { json, error in
				if let error = error {
					XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
					return
				}

				guard let jsonArray = json?["rows"].array else {
					XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
					return
				}

				XCTAssert(jsonArray.count == documents.count, "Incorrect number of documents retrieved, error: Couldn't insert all documents")

				// Build the payload sent for bulk deletion by extracting ID and REV values from the retrieved JSON array
				let documentsToDelete = jsonArray.map() {
					JSON(["_id": $0["id"], "_rev": $0["value"]["rev"], "_deleted": JSON(true)])
				}

				// Bulk delete documents
				database.bulk(documents: documentsToDelete) { json, error in
					if let error = error {
						XCTFail("Failed to bulk delete documents from database, error: \(error.localizedDescription)")
						return
					}

					guard let jsonArray = json?.array else {
						XCTFail("Failed to convert response JSON to an object array, error: Invalid response data")
						return
					}

					// Check if all documents were deleted successfully
					let success = jsonArray.reduce(true) { $0 && ($1["ok"].bool ?? false) }

					guard success == true else {
						XCTFail("Failed to bulk delete documents from database, error: Not all documents were deleted successfully")
						return
					}

					// Get all documents (there should be nont)
					database.retrieveAll() { json, error in
						if let error = error {
							XCTFail("Failed to retrieve all documents, error: \(error.localizedDescription)")
							return
						}

						XCTAssert(json?["rows"].array?.count == 0, "Failed to bulk delete documents from database, error: Not all documents were deleted")
					}
				}
			}
		}
	}
}

