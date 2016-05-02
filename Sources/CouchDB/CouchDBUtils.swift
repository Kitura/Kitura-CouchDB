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
import KituraNet
import SwiftyJSON

class CouchDBUtils {

    static let couchDBDomain = "CouchDBDomain"

    class func createError(_ code: HttpStatusCode, id: String?, rev: String?) -> NSError {
        return createError(code.rawValue, desc: Http.statusCodes[code.rawValue], id: id, rev: rev)
    }

    class func createError(_ code: Int, id: String?, rev: String?) -> NSError {
        return createError(code, desc: Database.Error[code], id: id, rev: rev)
    }

    class func createError(_ code: Int, desc: String?, id: String?, rev: String?) -> NSError {
        // Interim solution while Apple provides clear interoperability on both platforms
        #if os(Linux)
            var info = [String:Any]()
        #else
            var info = [String:String]()
        #endif

        info[NSLocalizedDescriptionKey] = desc
        if let id = id {
            info["id"] = id
        }
        if let rev = rev {
            info["rev"] = rev
        }
        return NSError(domain: couchDBDomain, code: code, userInfo: info)
    }

    class func createError(_ code: HttpStatusCode, errorDesc: JSON?, id: String?, rev: String?) -> NSError {
        if let errorDesc = errorDesc, let err = errorDesc["error"].string, let reason = errorDesc["reason"].string {
            return createError(code.rawValue, desc: "Error: \(err), reason: \(reason)", id: id, rev: nil)
        }
        return createError(code, id: id, rev: rev)
    }

    class func prepareRequest(_ connProperties: ConnectionProperties, method: String, path: String, hasBody: Bool, contentType: String = "application/json") -> [ClientRequestOptions] {
        var requestOptions = [ClientRequestOptions]()

        if let username = connProperties.username {
            requestOptions.append(.Username(username))
        }
        if let password = connProperties.password {
            requestOptions.append(.Password(password))
        }

        requestOptions.append(.Schema("\(connProperties.HTTPProtocol)://"))
        requestOptions.append(.Hostname(connProperties.host))
        requestOptions.append(.Port(connProperties.port))
        requestOptions.append(.Method(method))
        requestOptions.append(.Path(path))
        var headers = [String:String]()
        headers["Accept"] = "application/json"
        if hasBody {
            headers["Content-Type"] = contentType
        }
        requestOptions.append(.Headers(headers))
        return requestOptions
    }

    class func getBodyAsJson (_ response: ClientResponse) -> JSON? {
        do {
            let body = NSMutableData()
            try response.readAllData(into: body)
            let json = JSON(data: body)
            return json
        } catch {
            //Log this exception
        }
        return nil
    }

    class func getBodyAsNSData (_ response: ClientResponse) -> NSData? {
        do {
            let body = NSMutableData()
            try response.readAllData(into: body)
            return body
        } catch {
            //Log this exception
        }
        return nil
    }

}
