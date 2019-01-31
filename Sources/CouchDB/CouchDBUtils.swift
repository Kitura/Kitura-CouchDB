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
        requestOptions.append(.port(Int16(bitPattern: connProperties.port)))
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

    class func getBodyAsCodable<O: Decodable> (_ response: ClientResponse) throws -> O {
        do {
            var body = Data()
            try response.readAllData(into: &body)
            let codable = try JSONDecoder().decode(O.self, from: body)
            return codable
        } catch {
            throw error
        }
    }
    
    // decodes the Couch response as a `CouchDBError`
    // http://docs.couchdb.org/en/stable/json-structure.html#couchdb-error-status
    class func getBodyAsError(_ response: ClientResponse) -> CouchDBError {
        do {
            var body = Data()
            try response.readAllData(into: &body)
            var error = try JSONDecoder().decode(CouchDBError.self, from: body)
            error.statusCode = response.httpStatusCode.rawValue
            return error
        } catch {
            return CouchDBError(response.httpStatusCode.rawValue, id: nil, reason: error.localizedDescription)
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
    
    class func documentRequest<D: Document>(document: D, options: [ClientRequest.Options], callback: @escaping (DocumentResponse?, CouchDBError?) -> ()) {
        do {
            let requestBody = try JSONEncoder().encode(document)
            couchRequest(body: requestBody, options: options, passStatusCodes: [.created, .accepted], callback: callback)
        } catch {
            return callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: error.localizedDescription))
        }
    }
    
    class func deleteRequest(options: [ClientRequest.Options], callback: @escaping (CouchDBError?) -> ()) {
        struct DeleteResponse: Codable {
            let ok: Bool
        }
        couchRequest(options: options, passStatusCodes: [.OK, .accepted]) { (_: DeleteResponse?, error) in
            callback(error)
        }
    }
    
    class func couchRequest<O: Codable>(body: Data? = nil, options: [ClientRequest.Options], passStatusCodes: [HTTPStatusCode], callback: @escaping (O?, CouchDBError?) -> ()) {
        let req = HTTP.request(options) { response in
            if let response = response {
                guard passStatusCodes.contains(response.statusCode) else {
                    return callback(nil, CouchDBUtils.getBodyAsError(response))
                }
                do {
                    return callback(try CouchDBUtils.getBodyAsCodable(response), nil)
                } catch {
                    return callback(nil, CouchDBError(response.httpStatusCode, reason: error.localizedDescription))
                }
            } else {
                return callback(nil, CouchDBError(HTTPStatusCode.internalServerError, reason: "No HTTP response"))
            }
        }
        if let body = body {
            req.end(body)
        } else {
            req.end()
        }
    }
}


