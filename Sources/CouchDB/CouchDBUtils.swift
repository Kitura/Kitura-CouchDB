//
//  CouchDBUtils.swift
//  PhoenixCouchDB
//
//  Authors: Ira Rosen, Ricardo Olivieri
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import net
import router
import SwiftyJSON

class CouchDBUtils {

    static let couchDBDomain = "CouchDBDomain"

    class func createError(code: HttpStatusCode, id: String?, rev: String?) -> NSError {
        return createError(code.rawValue, desc: Http.statusCodes[code.rawValue], id: id, rev: rev)
    }

    class func createError(code: Int, id: String?, rev: String?) -> NSError {
        return createError(code, desc: Database.Error[code], id: id, rev: rev)
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

    class func prepareRequest(connProperties: ConnectionProperties, method: String, path: String, hasBody: Bool, contentType: String = "application/json") -> [ClientRequestOptions] {
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
        if hasBody {
            headers["Content-Type"] = contentType
        }
        requestOptions.append(.Headers(headers))

        for element in requestOptions {
          print("Request option: \(element)")
        }
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
        } catch {
          //TODO: Log this exception
        }
        return nil
    }

}
