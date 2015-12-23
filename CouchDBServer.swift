//
//  CouchDBServer.swift
//  SwiftCouchDB
//
//  Created by Ira Rosen on 14/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import net

import Foundation

public class CouchDBServer {
    var host: String?
    var port: Int16?
    
    
    public init (ipAddress: String, port: Int16) {
        host = ipAddress
        self.port = port
    }
    
    public func db (dbName: String) -> CouchDB {
        return CouchDB(server: self, dbName: dbName)
    }
    
    public func createDB (dbName: String, callback: (CouchDB?, NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(self, method: "PUT", path: "/\(Http.escapeUrl(dbName))", hasBody: false)
        let req = Http.request(requestOptions) { response in
            var error: NSError?
            var db: CouchDB?
            if let response = response {
                if response.statusCode == HttpStatusCode.CREATED {
                    db = CouchDB(server: self, dbName: dbName)
                }
                else {
                    error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            }
            else {
                error = CouchDBUtils.createError(CouchDB.ERROR_INTERNAL_ERROR, id: nil, rev: nil)
            }
            
            callback(db, error)
        }
        
        req.end()
    }
    
    public func deleteDB (db: CouchDB, callback: (NSError?) -> ()) {
        deleteDB(db.name, callback: callback)
    }
    
    public func deleteDB (dbName: String, callback: (NSError?) -> ()) {
        let requestOptions = CouchDBUtils.prepareRequest(self, method: "DELETE", path: "/\(Http.escapeUrl(dbName))", hasBody: false)
        let req = Http.request(requestOptions) { response in
            var error: NSError?
            if let response = response {
                if response.statusCode != HttpStatusCode.OK {
                    error = CouchDBUtils.createError(response.statusCode, id: nil, rev: nil)
                }
            }
            else {
                error = CouchDBUtils.createError(CouchDB.ERROR_INTERNAL_ERROR, id: nil, rev: nil)
            }
            
            callback(error)
        }
        
        req.end()
    }


}

