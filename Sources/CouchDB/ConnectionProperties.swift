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
import LoggerAPI

// MARK: ConnectionProperties

/// The connection properties of a `CouchDBClient` instance
public struct ConnectionProperties {

    /// Hostname or IP address to the CouchDB server
    public let host: String

    /// Port number where CouchDB server is listening for incoming connections
    public let port: Int

    /// Whether or not to use a secured connection
    public let secured: Bool

    // MARK: Authentication credentials to access CouchDB

    /// CouchDB admin username
    let username: String?

    /// CouchDB admin password
    let password: String?

    /// Initializes a `ConnectionProperties` instance.
    ///
    /// - parameters:
    ///     - host: Hostname or IP address to the CouchDB server.
    ///     - port: Port number where CouchDB server is listening for incoming connections.
    ///     - secured: Whether or not to use a secured connection.
    ///     - username: CouchDB admin username. Defaults to `nil`.
    ///     - password: CouchDB admin password. Defaults to `nil`.
    public init(host: String, port: Int, secured: Bool, username: String?=nil, password: String?=nil) {
        self.host = host
        self.port = port
        self.secured = secured
        self.username = username
        self.password = password
        if self.username == nil || self.password == nil {
            Log.warning("Initializing a CouchDB connection without a username or password.")
        }
    }

    // MARK: Computed properties

    /// Use https or http.
    var HTTPProtocol: String {
        return secured ? "https" : "http"
    }

    /// CouchDB URL.
    var URL: String {
        if let username = username, let password = password {
            return "\(HTTPProtocol)://\(username):\(password)@\(host):\(port)"
        } else {
            return "\(HTTPProtocol)://\(host):\(port)"
        }
    }
}

// MARK: Extension for <CustomStringConvertible>

extension ConnectionProperties: CustomStringConvertible {
    /// String description for a `ConnectionProperties`.
    public var description: String {
        return  "\thost -> \(host)\n" +
            "\tport -> \(port)\n" +
            "\tsecured -> \(secured)\n" +
            "\tusername -> \(String(describing: username))\n" +
            "\tpassword -> \(String(describing: password))\n" +
            "\tURL -> \(URL)"
    }
}
