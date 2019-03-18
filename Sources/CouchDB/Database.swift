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
import KituraNet

// MARK: Database

/**
 The `Database` class is used to make HTTP requests to the corresponding CouchDB database. This class can make CRUD (Create, Retrieve, Update, Delete) requests for:  
 
 - A single CouchDB `Document`
 - An array of CouchDB documents
 - A CouchDB `DesignDocument`
 - A `Document` attachment
*/
public class Database {
    
    // MARK: Database Properties
    
    /// Indicates when to update.
    public enum StaleOptions {
        /// CouchDB will not refresh the view even if it is stale.
        case OK
        /// CouchDB will update the view after the stale result is returned.
        case updateAfter
    }

    /// Query parameters for view functions from design documents.
    public enum QueryParameters {
        /// Includes conflicts information in response. Ignored if include_docs isn’t true. Default is false.
        case conflicts (Bool)

        /// Return the documents in descending by key order. Default is false.
        case descending (Bool)

        /// Stop returning records when the specified key is reached.
        case endKey ([Any])

        /// Stop returning records when the specified document ID is reached. Requires endkey to be specified for this to have any effect.
        case endKeyDocID (String)

        /// Group the results using the reduce function to a group or single row. Default is false
        case group (Bool)

        /// Specify the group level to be used.
        case groupLevel (Int)

        ///Include the associated document with each row. Default is false.
        case includeDocs (Bool)

        /// Include the Base64-encoded content of attachments in the documents that are included if include_docs is true. Ignored if include_docs isn’t true. Default is false.
        case attachments (Bool)

        /// Include encoding information in attachment stubs if include_docs is true and the particular attachment is compressed. Ignored if include_docs isn’t true. Default is false.
        case attachmentEncodingInfo (Bool)

        /// Specifies whether the specified end key should be included in the result. Default is true.
        case inclusiveEnd(Bool)

        /// Limit the number of the returned documents to the specified number.
        case limit (Int)

        /// Use the reduction function. Default is true.
        case reduce (Bool)

        /// Skip this number of records before starting to return the results. Default is 0.
        case skip (Int)

        ///  Allow the results from a stale view to be used.
        case stale (StaleOptions)

        /// Return records starting with the specified key.
        case startKey ([Any])

        ///  Return records starting with the specified document ID. Requires startkey to be specified for this to have any effect.
        case startKeyDocID (String)

        /// Response includes an update_seq value indicating which sequence id of the database the view reflects. Default is false.
        case updateSequence (Bool)

        /// Return only documents where the key matches one of the keys specified in the array.
        case keys ([Any])
    }

    /// Name for the Database.
    public let name: String

    /// Escaped name for the Database.
    public let escapedName: String

    /// `ConnectionProperties` the Database will use for its actions.
    public let connProperties: ConnectionProperties

    private static func createQueryParamForArray(_ array: [Any]) -> String {
        var result = "["
        var comma = ""
        for element in array {
            if let item = element as? String {
                result += "\(comma)\"\(HTTP.escape(url: item))\""
            } else {
                let objMirror = Mirror(reflecting: element)
                if objMirror.subjectType == NSObject.self {
                    result += "\(comma){}"
                } else {
                    result += "\(comma)\(element)"
                }
            }
            comma = ","
        }
        return result + "]"
    }

    // MARK: Initializer
    
    /// Initialize a new Database instance.
    ///
    /// - parameters:
    ///     - connProperties: `ConnectionProperties` the Database will use for its actions.
    ///     - dbName: String name for the Database.
    init(connProperties: ConnectionProperties, dbName: String) {
        self.name = dbName
        self.escapedName = HTTP.escape(url: name)
        self.connProperties = connProperties
    }

    // MARK: Single Documents requests
    
    /**
     Create a new document.
     ### Usage Example: ###
     ```swift
     struct MyDocument: Document {
         let _id: String?
         var _rev: String?
         var value: String
     }
     var myDocument = MyDocument(_id: "Kitura", _rev: nil, value: "Hello World")
     database.create(myDocument) { (response, error) in
        if let response = response {
            print("Document: \(response.id), created with rev: \(response.rev)")
        }
     }
     ```
    */
    /// - parameters:
    ///     - document: The new `Document`.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func create<D: Document>(_ document: D, callback: @escaping (DocumentResponse?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions, callback: callback)
    }

    /**
     Retrieve a document from the database.
     ### Usage Example: ###
     ```swift
     struct MyDocument: Document {
         let _id: String?
         var _rev: String?
         var value: String
     }
     database.retrieve("Kitura") { (document: MyDocument?, error: CouchDBError?) in
        if var document = document {
            print("Retrieved document with value: \(document.value)")
        }
     }
     ```
     */
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - callback: Callback containing either the `Document` or an `CouchDBError`.
    public func retrieve<D: Document>(_ id: String, callback: @escaping (D?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(escapedName)/\(HTTP.escape(url: id))", hasBody: false)
        CouchDBUtils.couchRequest(options: requestOptions, passStatusCodes: [.OK], callback: callback)
    }


	///
    /**
     Update a document in the database. If no document exists for the provided id, a new document is created.
     ### Usage Example: ###
     ```swift
     struct MyDocument: Document {
         let _id: String?
         var _rev: String?
         var value: String
     }
     var myDocument = MyDocument(_id: "Kitura", _rev: nil, value: "New Value")
     database.update("<document_id>", rev: "<latest_rev>", document: myDocument) { (response, error) in
         if let response = response {
            print("Document: \(response.id), updated")
         }
     }
     ```
     */
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - rev: The current revision number for the document.
    ///     - document: The new `Document`.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func update<D: Document>(_ id: String, rev: String, document: D, callback: @escaping (DocumentResponse?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions, callback: callback)
    }

    /**
     Delete a document.
     ### Usage Example: ###
     ```swift
     database.delete("<document_id>", rev: "<latest_rev>") { (error) in
         if let response = response {
            print("Document: \(response.id), deleted")
         }
     }
     ```
     */
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - rev: Latest revision String for the document.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func delete(_ id: String, rev: String, callback: @escaping (CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: false)
        CouchDBUtils.deleteRequest(options: requestOptions, callback: callback)
    }

    // MARK: Multiple Documents requests
    
    /// Bulk update or insert documents into the database.
    ///
    /// - Note:
    ///   - CouchDB will return the results in the same order as supplied in the array. The `id` and revision will be
    ///     added for every document passed as content to a bulk insert, even for those that were just deleted.
    ///   - If you omit the per-document `_id` specification, CouchDB will generate unique IDs for you, as it does for
    ///     regular `create(_:callback:)` function.
    ///   - Updating existing documents requires setting the `_rev` member to the revision being updated. To delete a
    ///     document set the `_deleted` member to `true`.
    ///     ````
    ///     [
    ///       {"_id": "0", "_rev": "1-62657917", "_deleted": true},
    ///       {"_id": "1", "_rev": "1-2089673485", "integer": 2, "string": "2"},
    ///       {"_id": "2", "_rev": "1-2063452834", "integer": 3, "string": "3"}
    ///     ]
    ///     ````
    ///   - If the `_rev` does not match the current version of the document, then that particular document will not be
    ///     saved and will be reported as a conflict, but this does not prevent other documents in the batch from being
    ///     saved.
    ///     ````
    ///     [
    ///       {"id": "0", "error": "conflict", "reason": "Document update conflict."},
    ///       {"id": "1", "rev": "2-1579510027"},
    ///       {"id": "2", "rev": "2-3978456339"}
    ///     ]
    ///     ````
    ///
    /// - Parameter documents: An `BulkDocuments` struct containing an array of JSON documents to be updated or inserted.
    /// - Parameter callback: callback containing either a `BulkResponse` array or an error.
    ///
    public func bulk(documents: BulkDocuments, callback: @escaping ([BulkResponse]?, CouchDBError?) -> ()) {
        
        // Prepare request options
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)/_bulk_docs", hasBody: true)
        
        let body: [String : Any] = ["docs": documents.docs, "new_edits": documents.new_edits ?? true]
        // Create request body and check if it was generated successfully
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
            CouchDBUtils.couchRequest(body: requestBody, options: requestOptions, passStatusCodes: [.OK, .created], callback: callback)
        } catch {
            callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: error.localizedDescription))
        }
    }
    
    /// Executes the specified view function from the specified design document.
    ///
    /// - parameters:
    ///     - view: View function name String.
    ///     - design: Design document name.
    ///     - params: Query parameters for the function.
    ///     - callback: Callback containing either the `AllDatabaseDocuments` or a `CouchDBError`.
    public func queryByView(_ view: String, ofDesign design: String, usingParameters params: [Database.QueryParameters], callback: @escaping (AllDatabaseDocuments?, CouchDBError?) -> ()) {
        var paramString = ""
        var keys: [Any]?

        for param in params {
            switch param {
            case .conflicts (let value):
                paramString += "conflicts=\(value)&"
            case .descending (let value):
                paramString += "descending=\(value)&"
            case .endKey (let value):
                if value.count == 1 {
                    if let endKey = value[0] as? String {
                        paramString += "endkey=\"\(HTTP.escape(url: endKey))\"&"
                    } else {
                        paramString += "endkey=\(value[0])&"
                    }
                } else {
                    paramString += "endkey=" + Database.createQueryParamForArray(value) + "&"
                }
            case .endKeyDocID (let value):
                paramString += "endkey_docid=\"\(HTTP.escape(url: value))\"&"
            case .group (let value):
                paramString += "group=\(value)&"
            case .groupLevel (let value):
                paramString += "group_level=\(value)&"
            case .includeDocs (let value):
                paramString += "include_docs=\(value)&"
            case .attachments (let value):
                paramString += "attachments=\(value)&"
            case .attachmentEncodingInfo (let value):
                paramString += "att_encoding_info=\(value)&"
            case .inclusiveEnd (let value):
                paramString += "inclusive_end=\(value)&"
            case .limit (let value):
                paramString += "limit=\(value)&"
            case .reduce (let value):
                paramString += "reduce=\(value)&"
            case .skip (let value):
                paramString += "skip=\(value)&"
            case .stale (let value):
                paramString += "stale=\"\(value)\"&"
            case .startKey (let value):
                if value.count == 1 {
                    if let startKey = value[0] as? String {
                        paramString += "startkey=\"\(HTTP.escape(url: startKey))\"&"
                    } else {
                        paramString += "startkey=\(value[0])&"
                    }
                } else {
                    paramString += "startkey=" + Database.createQueryParamForArray(value) + "&"
                }
            case .startKeyDocID (let value):
                paramString += "start_key_doc_id=\"\(HTTP.escape(url: value))\"&"
            case .updateSequence (let value):
                paramString += "update_seq=\(value)&"
            case .keys (let value):
                if value.count == 1 {
                    if value[0] is String {
                        paramString += "key=\"\(HTTP.escape(url: value[0] as! String))\"&"
                    } else if let anyArray = value[0] as? [Any] {
                        paramString += "key=" + Database.createQueryParamForArray(anyArray) + "&"
                    }
                } else {
                    keys = value
                }
            }
        }

        if paramString.count > 0 {
            paramString = "?" + String(paramString.dropLast())
        }

        var method = "GET"
        var hasBody = false
        let body: [String: Any]?
        if let keys = keys {
            method = "POST"
            hasBody = true
            body = ["keys": keys]
        } else {
            body = nil
        }

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: method, path: "/\(escapedName)/_design/\(HTTP.escape(url: design))/_view/\(HTTP.escape(url: view))\(paramString)", hasBody: hasBody)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == HTTPStatusCode.OK else {
                    return callback(nil, CouchDBUtils.getBodyAsError(response))
                }
                if let bodyData = CouchDBUtils.getBodyAsData(response),
                    let bodyJSON = (try? JSONSerialization.jsonObject(with: bodyData, options: [])) as? [String:Any],
                    let total_rows = bodyJSON["total_rows"] as? Int,
                    let offset = bodyJSON["offset"] as? Int,
                    let rows = bodyJSON["rows"] as? [[String: Any]]
                {
                    return callback(AllDatabaseDocuments(total_rows: total_rows, offset: offset, rows: rows), nil)
                } else {
                    return callback(nil, CouchDBError(.internalServerError, reason: "Failed to decode AllDatabaseDocuments from response"))
                }
            } else {
                callback(nil, CouchDBError(.internalServerError, reason: "No response from queryByView request"))
            }
        }

        if let body = body, let bodyAsData = try? JSONSerialization.data(withJSONObject: body, options: []) {
            req.end(bodyAsData)
        } else {
            req.end()
        }
    }

    
    /**
     Retrieve all documents in the database using the CouchDB `_all_docs` view.
     If `includeDocuments` is false, each returned `AllDatabaseDocuments` row will be structured as follows:
     ```
     [
        "id": "<_id>",
        "key": "<_id>",
        "value": [ "rev": "<_rev>" ]
     ]
     ```
     If `includeDocuments` is true, each row will have an additional "doc" field containing the JSON document.
     These documents can then be decoded to a given swift type using `decodeDocuments(ofType:)`.
     https://docs.couchdb.org/en/stable/api/database/bulk-api.html  
     ### Usage Example: ###
     ```swift
     struct MyDocument: Document {
         let _id: String?
         var _rev: String?
         var value: String
     }
     database.retrieveAll(includeDocuments: true) { (allDocs, error) in
         if let allDocs = allDocs,
             let decodedDocs = allDocs.decodeDocuments(ofType: MyDocument)
         {
             for doc in decodedDocs {
                 print("Retrieved MyDocument with value: \(doc.value)")
             }
         }
     }
     ```
     */
    /// - parameters:
    ///     - includeDocuments: Bool indicating whether to return the full contents of the documents.
    ///                         Defaults to `false`.
    ///     - callback: Callback containing `AllDatabaseDocuments` or a `CouchDBError` if one occurred.
    public func retrieveAll(includeDocuments: Bool = false, callback: @escaping (AllDatabaseDocuments?, CouchDBError?) -> ()) {
        var path = "/\(escapedName)/_all_docs"
        if includeDocuments {
            path += "?include_docs=true"
        }
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: path, hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == HTTPStatusCode.OK else {
                    return callback(nil, CouchDBUtils.getBodyAsError(response))
                }
                if let bodyData = CouchDBUtils.getBodyAsData(response),
                    let bodyJSON = (try? JSONSerialization.jsonObject(with: bodyData, options: [])) as? [String:Any],
                    let total_rows = bodyJSON["total_rows"] as? Int,
                    let offset = bodyJSON["offset"] as? Int,
                    let rows = bodyJSON["rows"] as? [[String: Any]]
                {
                    return callback(AllDatabaseDocuments(total_rows: total_rows, offset: offset, rows: rows), nil)
                } else {
                    return callback(nil, CouchDBError(.internalServerError, reason: "Failed to decode AllDatabaseDocuments from response"))
                }
            } else {
                callback(nil, CouchDBError(.internalServerError, reason: "No response from queryByView request"))
            }
        }
        req.end()
    }
    
    // MARK: Design Documents
    
    /// Create a design document. If a design document already exists with the same name it will be replaced.
    ///
    /// - parameters:
    ///     - designName: Name String for the design document.
    ///     - document: The JSON data of the new design document.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func createDesign(_ designName: String, document: DesignDocument, callback: @escaping (DocumentResponse?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions, callback: callback)
    }

    /// Delete a design document.
    ///
    /// - parameters:
    ///     - designName: Name String of the design document to delete.
    ///     - revision: The latest revision String of the design document to delete.
    ///     - failOnNotFound: Bool indicating whether to return an error if the design document was not found.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func deleteDesign(_ designName: String, revision: String, failOnNotFound: Bool = false, callback: @escaping (CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))?rev=\(HTTP.escape(url: revision))", hasBody: false)
        CouchDBUtils.deleteRequest(options: requestOptions, callback: callback)
    }

    // MARK: Attachments
    
    /// Attach the provided `Data` the `Document` with the provided ID with the given attachmentName.
    /// If an attachment exists with the same name it will be replaced with the new attachment.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - docRevision: Document revision String.
    ///     - attachmentName: Attachment name String.
    ///     - attachmentData: The attachment Data.
    ///     - contentType: Attachment MIME type String.
    ///     - callback: Callback containing the `DocumentResponse` or a `CouchDBError`.
    public func createAttachment(_ docId: String, docRevison: String, attachmentName: String, attachmentData: Data, contentType: String, callback: @escaping (DocumentResponse?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: true, contentType: contentType)
        CouchDBUtils.couchRequest(body: attachmentData, options: requestOptions, passStatusCodes: [.created, .accepted], callback: callback)
    }

    /// Get an attachment associated with a specified document.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - attachmentName: Name String for the desired attachment.
    ///     - callback: Callback containing either the retrieved attachment data and the content type of the attachment or a `CouchDBError`.
    public func retrieveAttachment(_ docId: String, attachmentName: String, callback: @escaping (Data?, String?, CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == HTTPStatusCode.OK else {
                    return callback(nil, nil, CouchDBUtils.getBodyAsError(response))
                }
                let attachment = CouchDBUtils.getBodyAsData(response)
                let contentType = response.headers["Content-Type"]?.first
                return callback(attachment, contentType, nil)
            } else {
                return callback(nil, nil, CouchDBError(.internalServerError, reason: "No response from retrieveAttachment request"))
            }
        }
        req.end()
    }

    /// Delete an attachment associated with a specified document.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - docRevision: Latest revision String of the document.
    ///     - attachmentName: Name String of the attachment to be deleted.
    ///     - callback: Callback containing either the `DocumentResponse` or a `CouchDBError`.
    public func deleteAttachment(_ docId: String, docRevison: String, attachmentName: String, callback: @escaping (CouchDBError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: false)
        CouchDBUtils.deleteRequest(options: requestOptions, callback: callback)
    }
}
