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

class CouchDBUtils {
    static let couchDBDomain = "CouchDBDomain"

    class func createError(_ code: HTTPStatusCode, id: String?, rev: String?) -> NSError {
        return createError(code.rawValue, desc: HTTPURLResponse.localizedString(forStatusCode: code.rawValue), id: id, rev: rev)
    }

    class func createError(_ code: Int, id: String?, rev: String?) -> NSError {
        return createError(code, desc: Database.Error[code], id: id, rev: rev)
    }

    class func createError(_ code: Int, desc: String?, id: String?, rev: String?) -> NSError {
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

    class func createError(_ code: HTTPStatusCode, errorDesc: CouchErrorResponse?, id: String?, rev: String?) -> NSError {
        if let errorDesc = errorDesc {
            return createError(code.rawValue, desc: "Error: \(errorDesc.error), reason: \(errorDesc.reason)", id: id, rev: nil)
        }
        return createError(code, id: id, rev: rev)
    }

    class func prepareRequest(_ connProperties: ConnectionProperties, method: String, path: String, hasBody: Bool, contentType: String = "application/json") -> [ClientRequest.Options] {
        var requestOptions: [ClientRequest.Options] = []

        if let username = connProperties.username {
            requestOptions.append(.username(username))
        }
        if let password = connProperties.password {
            requestOptions.append(.password(password))
        }
        requestOptions.append(.schema("\(connProperties.HTTPProtocol)://"))
        requestOptions.append(.hostname(connProperties.host))
        requestOptions.append(.port(connProperties.port))
        requestOptions.append(.method(method))
        requestOptions.append(.path(path))
        var headers = [String:String]()
        headers["Accept"] = "application/json"
        if hasBody {
            headers["Content-Type"] = contentType
        }
        requestOptions.append(.headers(headers))
        return requestOptions
    }

    class func getBodyAsCodable<O: Decodable> (_ response: ClientResponse) -> O? {
        do {
            var body = Data()
            try response.readAllData(into: &body)
            let codable = try JSONDecoder().decode(O.self, from: body)
            return codable
        } catch {
            //Log this exception
            return nil
        }
    }

    class func getBodyAsData (_ response: ClientResponse) -> Data? {
        do {
            var body = Data()
            try response.readAllData(into: &body)
            return body
        } catch {
            //Log this exception
        }
        return nil
    }
    
    class func makeRequest<D: Document>(document: D, options: [ClientRequest.Options], callback: @escaping (DocumentResponse?, NSError?) -> ()) {
        if let requestBody = try? JSONEncoder().encode(document) {
            var doc: DocumentResponse?
            let req = HTTP.request(options) { response in
                var error: NSError?
                if let response = response {
                    doc = CouchDBUtils.getBodyAsCodable(response)
                    if response.statusCode != HTTPStatusCode.created && response.statusCode != HTTPStatusCode.accepted {
                        let errorDesc: CouchErrorResponse? = CouchDBUtils.getBodyAsCodable(response)
                        error = CouchDBUtils.createError(response.statusCode, errorDesc: errorDesc, id: document._id, rev: nil)
                    }
                } else {
                    error = CouchDBUtils.createError(Database.InternalError, id: document._id, rev: nil)
                }
                callback(doc, error)
            }
            req.end(requestBody)
        } else {
            callback(nil, CouchDBUtils.createError(Database.InvalidDocument, id: document._id, rev: document._rev))
        }
    }
}


