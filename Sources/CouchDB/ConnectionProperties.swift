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

// MARK: ConnectionProperties

public class ConnectionProperties {

  // Hostname or IP address to the CouchDB server
  public let hostName: String

  // Port number where CouchDB server is listening for incoming connections
  public let port: Int16

  // Seucred boolean
  public let secured: Bool

  // Authentication credentials to access Cloudant
  // Cloudant username
  let userName: String?

  // Cloudant password
  let password: String?

  // Cloudant URL
  // Derived instance variable
  let url: String?

  public init(hostName: String, port: Int16, secured: Bool, userName: String?, password: String?) {
      self.hostName = hostName
      self.port = port
      self.userName = userName
      self.password = password
      self.secured = secured
      let httpProtocol = ConnectionProperties.deriveHttpProtocol(secured)
      if userName != nil && password != nil {
        self.url = "\(httpProtocol)://\(userName):\(password)\(hostName):\(port)"
      } else {
        self.url = "\(httpProtocol)://\(hostName):\(port)"
      }
  }

  public convenience init(hostName: String, port: Int16, secured: Bool) {
    self.init(hostName: hostName, port: port, secured: secured, userName: nil, password: nil)
  }

  public func toString() -> String {
    let user = self.userName != nil ? self.userName : ""
    let pwd = self.password != nil ? self.password : ""
    let str = "\thostName -> \(hostName)\n" +
      "\tport -> \(port)\n" +
      "\tsecured -> \(secured)\n" +
      "\tuserName -> \(user)\n" +
      "\tpassword -> \(pwd)"
    return str
  }

  static func deriveHttpProtocol(secured: Bool) -> String {
    let httpProtocol = (secured) ? "https" : "http"
    return httpProtocol
  }

}
