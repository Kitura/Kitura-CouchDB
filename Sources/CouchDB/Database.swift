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

/// Represents a CouchDB database.
public class Database {
    
    // MARK: Database Properties
    
    /// Indicates when to update.
    public struct StaleOptions: Equatable {
        
        /// A String description of the StaleOptions instance.
        public let description: String
        
        init(description: String) {
            self.description = description
        }
        /// CouchDB will not refresh the view even if it is stale.
        static let OK = StaleOptions(description: "OK")
        
        /// CouchDB will update the view after the stale result is returned.
        static let updateAfter = StaleOptions(description: "updateAfter")
        
        /// Check if two StaleOptions are equal. Required to conform to the Equatable protocol.
        public static func == (lhs: StaleOptions, rhs: StaleOptions) -> Bool {
            return lhs.description == rhs.description
        }
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

    /// Dictionary of Error cases.
    public static let Error = [
        InternalError: "Internal Error",
        InvalidDocument: "Invalid Document Body",
        InvalidAttachment: "Invalid attachment"
    ]

    /// Internal error.
    public static let InternalError = 0

    /// Invalid document.
    public static let InvalidDocument = 1

    /// Invalid attachment.
    public static let InvalidAttachment = 2

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
    public init (connProperties: ConnectionProperties, dbName: String) {
        self.name = dbName
        self.escapedName = HTTP.escape(url: name)
        self.connProperties = connProperties
    }

    // MARK: Single Documents requests
    
    /// Retrieve a document from the database by ID.
    ///
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - callback: Callback containing the document JSON or an NSError if one occurred.
    public func retrieve<D: Document>(_ id: String, callback: @escaping (D?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(escapedName)/\(HTTP.escape(url: id))", hasBody: false)
        var document: D?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                document = CouchDBUtils.getBodyAsCodable(response)
                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsCodable(response), id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
            }
            callback(document, error)
        }
        req.end()
    }


	/// Update a document in the database.
    ///
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - rev: The current revision number for the document.
    ///     - document: The new `Document`.
    ///     - callback: Callback containing the `DocumentResponse` or an NSError.
    public func update<D: Document>(_ id: String, rev: String, document: D, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions) { (response, error) in
            callback(response, error)
        }
    }

    /// Create a new document.
    ///
    /// - parameters:
    ///     - document: The new `Document`.
    ///     - callback: Callback containing the ID of the newly created document, revision number,
    ///                 JSON response, and NSError if one occurred.
    public func create<D: Document>(_ document: D, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions) { (response, error) in
            callback(response, error)
        }
    }

    /// Delete a document.
    ///
    /// - parameters:
    ///     - id: String ID for the document.
    ///     - rev: Latest revision String for the document.
    ///     - failOnNotFound: Bool indicating whether to return an error if the document is not found.
    ///     - callback: Callback containing an NSError if one occurred.
    public func delete(_ id: String, rev: String, failOnNotFound: Bool = false, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: false)
        CouchDBUtils.deleteRequest(id: id, rev: rev, failOnNotFound: failOnNotFound, options: requestOptions, callback: callback)
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
    public func bulk(documents: BulkDocuments, callback: @escaping ([BulkResponse]?, NSError?) -> ()) {
        
        // Prepare request options
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)/_bulk_docs", hasBody: true)
        
        let body: [String : Any] = ["docs": documents.docs, "new_edits": documents.new_edits ?? true]
        // Create request body and check if it was generated successfully
        guard let requestBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            callback(nil, CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
            return
        }
        
        // Create bulk update request and send it
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var documentsUpdateResult: [BulkResponse]?
            
            if let response = response {
                documentsUpdateResult = CouchDBUtils.getBodyAsCodable(response)
                if response.statusCode != HTTPStatusCode.OK && response.statusCode != HTTPStatusCode.created {
                    let responseError: CouchErrorResponse? = CouchDBUtils.getBodyAsCodable(response)
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: responseError, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(documentsUpdateResult, error)
        }
        req.end(requestBody)
    }
    
    /// Executes the specified view function from the specified design document.
    ///
    /// - parameters:
    ///     - view: View function name String.
    ///     - design: Design document name.
    ///     - params: Query parameters for the function.
    ///     - callback: Callback containing the JSON response or NSError if one occurred.
    ///                 Refer to http://docs.couchdb.org/en/2.1.0/api/ddoc/views.html for info on JSON contents.
    public func queryByView(_ view: String, ofDesign design: String, usingParameters params: [Database.QueryParameters], callback: @escaping (AllDatabaseDocuments?, NSError?) -> ()) {
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
        var document: AllDatabaseDocuments?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if let bodyData = CouchDBUtils.getBodyAsData(response),
                    let bodyJSON = (try? JSONSerialization.jsonObject(with: bodyData, options: [])) as? [String:Any],
                    let total_rows = bodyJSON["total_rows"] as? Int,
                    let offset = bodyJSON["offset"] as? Int,
                    let rows = bodyJSON["rows"] as? [[String: Any]]
                {
                    document = AllDatabaseDocuments(total_rows: total_rows, offset: offset, rows: rows)
                }
                if response.statusCode != HTTPStatusCode.OK {
                    let responseError: CouchErrorResponse? = CouchDBUtils.getBodyAsCodable(response)
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: responseError, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(document, error)
        }

        if let body = body, let bodyAsData = try? JSONSerialization.data(withJSONObject: body, options: []) {
            req.end(bodyAsData)
        } else {
            req.end()
        }
    }

    
    /// Retrieve all documents from the database
    ///
    /// - parameters:
    ///     - includeDocuments: Bool indicating whether to return the full contents of the documents.
    ///                         Defaults to `false`.
    ///     - callback: Callback containing AllDatabaseDocuments or an NSError if one occurred.
    public func retrieveAll(includeDocuments: Bool = false, callback: @escaping (AllDatabaseDocuments?, NSError?) -> ()) {
        var path = "/\(escapedName)/_all_docs"
        if includeDocuments {
            path += "?include_docs=true"
        }
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: path, hasBody: false)
        var document: AllDatabaseDocuments?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if let bodyData = CouchDBUtils.getBodyAsData(response),
                    let bodyJSON = (try? JSONSerialization.jsonObject(with: bodyData, options: [])) as? [String:Any],
                    let total_rows = bodyJSON["total_rows"] as? Int,
                    let offset = bodyJSON["offset"] as? Int,
                    let rows = bodyJSON["rows"] as? [[String:Any]]
                {
                    document = AllDatabaseDocuments(total_rows: total_rows, offset: offset, rows: rows)
                }
                
                if response.statusCode != HTTPStatusCode.OK {
                    let responseError: CouchErrorResponse? = CouchDBUtils.getBodyAsCodable(response)
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: responseError, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(document, error)
        }
        req.end()
    }
    
    // MARK: Design Documents
    
    /// Create a design document.
    ///
    /// - parameters:
    ///     - designName: Name String for the design document.
    ///     - document: The JSON data of the new design document.
    ///     - callback: Callback containing the JSON response or an NSError if one occurred.
    public func createDesign(_ designName: String, document: DesignDocument, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))", hasBody: true)
        CouchDBUtils.documentRequest(document: document, options: requestOptions, callback: callback)
    }

    /// Delete a design document.
    ///
    /// - parameters:
    ///     - designName: Name String of the design document to delete.
    ///     - revision: The latest revision String of the design document to delete.
    ///     - failOnNotFound: Bool indicating whether to return an error if the design document was not found.
    ///     - callback: Callback containing an NSError if one occurred.
    public func deleteDesign(_ designName: String, revision: String, failOnNotFound: Bool = false, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))?rev=\(HTTP.escape(url: revision))", hasBody: false)
        CouchDBUtils.deleteRequest(id: designName, rev: revision, failOnNotFound: failOnNotFound, options: requestOptions, callback: callback)
    }

    // MARK: Attachments
    
    /// Create an attachment.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - docRevision: Document revision String.
    ///     - attachmentName: Attachment name String.
    ///     - attachmentData: The attachment Data.
    ///     - contentType: Attachment MIME type String.
    ///     - callback: Callback containing the new revision String, the JSON response,
    ///                 and an NSError if one occurred.
    public func createAttachment(_ docId: String, docRevison: String, attachmentName: String, attachmentData: Data, contentType: String, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: true, contentType: contentType)
        CouchDBUtils.couchRequest(id: docId, rev: docRevison, body: attachmentData, options: requestOptions, passStatusCodes: [.created, .accepted], callback: callback)
    }

    /// Get an attachment associated with a specified document.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - attachmentName: Name String for the desired attachment.
    ///     - callback: Callback containing either the retrieved attachment data and the content type of the attachment or an NSError.
    public func retrieveAttachment(_ docId: String, attachmentName: String, callback: @escaping (Data?, String?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            var attachment: Data?
            var contentType: String?
            if let response = response {
                attachment = CouchDBUtils.getBodyAsData(response)
                contentType = response.headers["Content-Type"]?.first
                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, id: docId, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: docId, rev: nil)
            }
            callback(attachment, contentType, error)
        }
        req.end()
    }

    /// Delete an attachment associated with a specified document.
    ///
    /// - parameters:
    ///     - docId: Document ID String that the attachment is associated with.
    ///     - docRevision: Latest revision String of the document.
    ///     - attachmentName: Name String of the attachment to be deleted.
    ///     - failOnNotFound: Bool indicating whether to return an NSError if the attachment could not be found.
    ///     - callback: Callback containing an NSError if one occurred.
    public func deleteAttachment(_ docId: String, docRevison: String, attachmentName: String, failOnNotFound: Bool = false, callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: false)
        CouchDBUtils.deleteRequest(id: docId, rev: docRevison, failOnNotFound: failOnNotFound, options: requestOptions, callback: callback)
    }
}
