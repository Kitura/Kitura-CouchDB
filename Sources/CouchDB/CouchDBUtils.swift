//
//  Utils.swift
//  SwiftCouchDB
//
//  Created by Ira Rosen on 21/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import net
import router

import SwiftyJSON

import Foundation

class CouchDBUtils {

    static let couchDBDomain = "CouchDBDomain"

    class func createError(code: HttpStatusCode, id: String?, rev: String?) -> NSError {
        return createError(code.rawValue, desc: Http.statusCodes[code.rawValue], id: id, rev: rev)
    }

    class func createError(code: Int, id: String?, rev: String?) -> NSError {
        return createError(code, desc: CouchDB.CouchDBError[code], id: id, rev: rev)
    }

    class func createError(code: Int, desc: String?, id: String?, rev: String?) -> NSError {
        var info = [String:String]()
        info[NSLocalizedDescriptionKey] = desc
        if let id = id {
            info["id"] = id
        }
        if let rev = rev {
            info["rev"] = rev
        }
        return NSError(domain: couchDBDomain, code: code, userInfo: info)
    }

    class func createError(code: HttpStatusCode, errorDesc: JSON?, id: String?, rev: String?) -> NSError {
        if let errorDesc = errorDesc, let err = errorDesc["error"].string, let reason = errorDesc["reason"].string {
            return createError(code.rawValue, desc: "Error: \(err), reason: \(reason)", id: id, rev: nil)
        }
        return createError(code, id: id, rev: rev)
    }

    //TODO
    class func prepareRequest2 (connProperties: ConnectionProperties, method: String, path: String, hasBody: Bool, contentType: String = "application/json") -> [ClientRequestOptions] {
        var requestOptions = [ClientRequestOptions]()

        if let userName = connProperties.userName {
          requestOptions.append(.Username(userName))
        }

        if let password = connProperties.password {
          requestOptions.append(.Password(password))
        }

        requestOptions.append(.Hostname(connProperties.hostName))
        requestOptions.append(.Port(connProperties.port))
        requestOptions.append(.Method(method))
        requestOptions.append(.Path(path))
        var headers = [String:String]()
        headers["Accept"] = "application/json"
        if hasBody == true {
            headers["Content-Type"] = contentType
        }
        requestOptions.append(.Headers(headers))

        for element in requestOptions {
          print("Request option: \(element)")
        }

        return requestOptions
    }
    //TODO


    class func prepareRequest (server: CouchDBServer, method: String, path: String, hasBody: Bool, contentType: String = "application/json") -> [ClientRequestOptions] {
        var requestOptions = [ClientRequestOptions]()
        requestOptions.append(.Hostname(server.host!))
        requestOptions.append(.Port(server.port!))
        requestOptions.append(.Method(method))
        requestOptions.append(.Path(path))
        var headers = [String:String]()
        headers["Accept"] = "application/json"
        if hasBody == true {
            headers["Content-Type"] = contentType
        }
        requestOptions.append(.Headers(headers))
        return requestOptions
    }

    class func getBodyAsJson (response: ClientResponse) -> JSON? {
        if let body = BodyParser.parse(response, contentType: response.headers["Content-Type"]) {
            return JSON(body)
        }
        return nil
    }

    class func getBodyAsNSData (response: ClientResponse) -> NSData? {
        do {
            let body = try BodyParser.readBodyData(response)
            return body
        }
        catch {
        }
        return nil
    }


}
