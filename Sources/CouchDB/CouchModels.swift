//
//  CouchModels.swift
//  CouchDB
//
//  Created by Andrew Lees on 02/11/2018.
//

import Foundation

// http://docs.couchdb.org/en/stable/json-structure.html#userctx-object

public struct CouchUser: Codable {    
    public let id: String
    public let name: String
    public let roles: [String]
    public let type: String
    public let password: String
    public init(name: String, roles: [String], type: String, password: String) {
        self.name = name
        self.roles = roles
        self.type = type
        self.password = password
        self.id = "org.couchdb.user:" + name
    }
}

public struct CouchResponse: Codable {
    public let ok: Bool
    public let id: String?
    public let rev: String?
}

public struct SessionResponse: Codable {
    public let ok: Bool
    public let name: String?
    public let roles: [String]?
    public let userCtx: UserContextObject?
    public let info: SessionInfo?
}

public struct CouchErrorResponse: Codable {
    public let id: String
    public let error: String
    public let reason: String
}

public struct UserContextObject: Codable {
    public let db: String
    public let name: String
    public let roles: [String]
}

public struct SessionInfo: Codable {
    public let authenticated: String
    public let authentication_db: String
    public let authentication_handlers: [String]
}

public struct AllDatabaseDocuments {
    init(total_rows: Int, offset: Int, rows: [Data]) {
        self.total_rows = total_rows
        self.offset = offset
        self.rows = rows
    }
    public let total_rows: Int
    public let offset: Int
    public let rows: [Data]
}

public protocol Document: Codable {
    var _id: String? { get }
    var _rev: String? { get }
}

// http://docs.couchdb.org/en/2.2.0/api/ddoc/common.html#put--db-_design-ddoc
public struct DesignDocument: Codable, Document {
    public let _id: String?
    public let _rev: String?
    public let language: String?
    public let options: [String: Bool]?
    public let filters: [String: String]?
    public let lists: [String: String]?
    public let rewrites: [String]?
    public let shows: [String: String]?
    public let updates: [String: String]?
    public let validate_doc_update: String?
    public let views: [String: [String: String]]?
}

// http://docs.couchdb.org/en/2.2.0/api/database/bulk-api.html#db-bulk-docs
public struct BulkResponse: Codable {
    public let id: String
    public let rev: String?
    public let error: String?
    public let reason: String?
}

public struct BulkDocuments {
    public let new_edits: Bool
    public let docs: [Data]
}
