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

import Foundation
import SwiftyJSON
import KituraNet

// MARK: Database

public class Database {

    ///
    /// Options handling when to update
    ///
    /// - OK: CouchDB will not refresh the view even if it is stale
    /// - UpdateAfter: CouchDB will update the view after the stale result is returned
    ///
    public enum StaleOptions {
        case OK
        case updateAfter
    }

    #if os(Linux)
    public typealias KeyType = Any
    #else
    public typealias KeyType = AnyObject
    #endif

    public enum QueryParameters {
        case conflicts (Bool)
        case descending (Bool)
        case endKey ([KeyType])
        case endKeyDocID (String)
        case group (Bool)
        case groupLevel (Int)
        case includeDocs (Bool)
        case attachments (Bool)
        case attachmentEncodingInfo (Bool)
        case inclusiveEnd(Bool)
        case limit (Int)
        case reduce (Bool)
        case skip (Int)
        case stale (StaleOptions)
        case startKey ([KeyType])
        case startKeyDocID (String)
        case updateSequence (Bool)
        case keys ([KeyType])
    }

    public static let Error = [
                                  InternalError: "Internal Error",
                                  InvalidDocument: "Invalid Document Body",
                                  InvalidAttachment: "Invalid attachment"
    ]

    public static let InternalError = 0
    public static let InvalidDocument = 1
    public static let InvalidAttachment = 2

    public let name: String
    public let escapedName: String
    public let connProperties: ConnectionProperties

    private static func createQueryParamForArray(_ array: [KeyType]) -> String {
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

    ///
    /// Initializes a new Database instance
    ///
    /// - Parameter connProperties: ConnectionProperty to use
    /// - Parameter dbName: the String representing the database name
    ///
    /// - Returns: a new Database instance
    ///
    public init (connProperties: ConnectionProperties, dbName: String) {
        self.name = dbName
        self.escapedName = HTTP.escape(url: name)
        self.connProperties = connProperties
    }

    ///
    /// Retrieve a document from the database by ID
    ///
    /// - Parameter id: String ID for the document
    /// - Parameter callback: callback function with the document's JSON
    ///
    public func retrieve(_ id: String, callback: @escaping (JSON?, NSError?) -> ()) {

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: "/\(escapedName)/\(HTTP.escape(url: id))", hasBody: false)
        var document: JSON?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)
                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: id, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: nil)
            }
            callback(document, error)
        }
        req.end()
    }

    ///
    /// Retrieve all documents from the database
    ///
    /// - Parameter includeDocuments: A boolean value that indicates whether to include the full content
    ///                               of the documents. Default is false.
    /// - Parameter callback: callback function with the document's JSON
    ///
    public func retrieveAll(includeDocuments: Bool = false, callback: @escaping (JSON?, NSError?) -> ()) {

        var path = "/\(escapedName)/_all_docs"
        if includeDocuments {
            path += "?include_docs=true"
        }
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET",
                                                         path: path, hasBody: false)
        var document: JSON?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)
                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(document, error)
        }
        req.end()
    }

    ///
    /// Update a document in the database
    ///
    /// - Parameter id: String ID for the document
    /// - Parameter rev: revision number
    /// - Parameter document: JSON data for the document
    /// - Parameter callback: callback containing the new document
    ///
    public func update(_ id: String, rev: String, document: JSON,
                       callback: @escaping (String?, JSON?, NSError?) -> ()) {

        if let requestBody = document.rawString() {
            var doc: JSON?
            var revision: String?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT",
                                                             path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: true)
            let req = HTTP.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsJson(response)
                    revision = doc?["rev"].string
                    if response.statusCode != .created && response.statusCode != .accepted {
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: id, rev: rev)
                    }
                } else {
                    error = CouchDBUtils.createError(Database.InternalError, id: id, rev: rev)
                }
                callback(revision, doc, error)
            }
            req.end(requestBody)
        } else {
            callback(nil, nil,
                     CouchDBUtils.createError(Database.InvalidDocument, id: id, rev: rev))
        }
    }

    ///
    /// Create a new document
    ///
    /// - Parameter documennt: JSON data for the document
    /// - Parameter callback: callback function with the new document
    ///
    public func create(_ document: JSON, callback: @escaping (String?, String?, JSON?, NSError?) -> ()) {
        if let requestBody = document.rawString() {
            var id: String?
            var doc: JSON?
            var revision: String?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)", hasBody: true)
            let req = HTTP.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsJson(response)
                    id = doc?["id"].string
                    revision = doc?["rev"].string
                    if response.statusCode != .created && response.statusCode != .accepted {
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: nil, rev: nil)
                    }
                } else {
                    error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
                }
                callback(id, revision, doc, error)
            }
            req.end(requestBody)
        } else {
            callback(nil, nil, nil, CouchDBUtils.createError(Database.InvalidDocument, id: nil, rev: nil))
        }
    }

    ///
    /// Deletes a document
    ///
    /// - Parameter id: String ID for the document
    /// - Parameter rev: revision ID
    /// - Parameter failOnNotFound: will throw an error if the document is not found
    /// - Parameter callback: a function containing an error
    ///
    public func delete(_ id: String, rev: String, failOnNotFound: Bool = false, callback: @escaping (NSError?) -> ()) {

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: id))?rev=\(HTTP.escape(url: rev))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if (response.statusCode != .OK && response.statusCode != .accepted)
                    || (response.statusCode == .notFound && failOnNotFound) {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: id, rev: rev)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: id, rev: rev)
            }
            callback(error)
        }
        req.end()
    }

    public func queryByView(_ view: String, ofDesign design: String, usingParameters params: [Database.QueryParameters], callback: @escaping (JSON?, NSError?) -> ()) {
        var paramString = ""
        var keys: [KeyType]?

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
                    } else if value[0] is [KeyType] {
                        paramString += "key=" + Database.createQueryParamForArray(value[0] as! [KeyType]) + "&"
                    }
                } else {
                    keys = value
                }
            }
        }

        if paramString.characters.count > 0 {
            paramString = "?" + String(paramString.characters.dropLast())
        }

        var method = "GET"
        var hasBody = false
        var body: JSON?
        if let keys = keys {
            method = "POST"
            hasBody = true
#if os(Linux)
            body = JSON(["keys": keys])
#else
            body = JSON(["keys": keys] as AnyObject)
#endif
        }

        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: method, path: "/\(escapedName)/_design/\(HTTP.escape(url: design))/_view/\(HTTP.escape(url: view))\(paramString)", hasBody: hasBody)
        var document: JSON?
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                document = CouchDBUtils.getBodyAsJson(response)
                if response.statusCode != HTTPStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
            }
            callback(document, error)
        }

        if let _ = body, let bodyAsString = body!.rawString() {
            req.end(bodyAsString)
        } else {
            req.end()
        }
    }

    public func createDesign(_ designName: String, document: JSON, callback: @escaping (JSON?, NSError?) -> ()) {
        if let requestBody = document.rawString() {
            var doc: JSON?
            let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))", hasBody: true)
            let req = HTTP.request(requestOptions) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsJson(response)
                    if response.statusCode != .created && response.statusCode != .accepted {
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: nil, rev: nil)
                    }
                } else {
                    error = CouchDBUtils.createError(Database.InternalError, id: nil, rev: nil)
                }
                callback(doc, error)
            }
            req.end(requestBody)
        } else {
            callback(nil, CouchDBUtils.createError(Database.InvalidDocument, id: designName, rev: nil))
        }
    }

    public func deleteDesign(_ designName: String, revision: String, failOnNotFound: Bool = false, callback: @escaping (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/_design/\(HTTP.escape(url: designName))?rev=\(HTTP.escape(url: revision))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if (response.statusCode != .OK && response.statusCode != .accepted)
                    || (response.statusCode == .notFound && failOnNotFound) {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: designName, rev: revision)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: designName, rev: revision)
            }
            callback(error)
        }
        req.end()
    }

    public func createAttachment(_ docId: String, docRevison: String, attachmentName: String, attachmentData: Data, contentType: String, callback: @escaping (String?, JSON?, NSError?) -> ()) {
        var doc: JSON?
        var revision: String?
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: true, contentType: contentType)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                doc = CouchDBUtils.getBodyAsJson(response)
                revision = doc?["rev"].string
                if response.statusCode != .created && response.statusCode != .accepted {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: docId, rev: docRevison)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: docId, rev: docRevison)
            }
            callback(revision, doc, error)
        }
        req.end(attachmentData)
    }

    public func retrieveAttachment(_ docId: String, attachmentName: String, callback: @escaping (Data?, NSError?, String?) -> ()) {
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
            callback(attachment, error, contentType)
        }
        req.end()
    }

    public func deleteAttachment(_ docId: String, docRevison: String, attachmentName: String, failOnNotFound: Bool = false, callback: @escaping (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(HTTP.escape(url: docId))/\(HTTP.escape(url: attachmentName))?rev=\(HTTP.escape(url: docRevison))", hasBody: false)
        let req = HTTP.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if (response.statusCode != .OK && response.statusCode != .accepted)
                    || (response.statusCode == .notFound && failOnNotFound) {
                    error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: docId, rev: docRevison)
                }
            } else {
                error = CouchDBUtils.createError(Database.InternalError, id: docId, rev: docRevison)
            }
            callback(error)
        }
        req.end()
    }
}
