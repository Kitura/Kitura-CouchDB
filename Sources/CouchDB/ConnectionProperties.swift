/**
 * Contains configuration properties for connecting to CouchDB or Cloudant instance.
 *
 * @author Ricardo Olivieri
 */

import Foundation

public class ConnectionProperties {

  // Hostname or IP address to the CouchDB server
  public let hostName: String

  // Port number where CouchDB server is listening for incoming connections
  public let port: Int16

  // The database name
  public let databaseName: String

  // Seucred boolean
  public let secured: Bool

  // Authentication credentials to access Cloudant
  // Cloudant username
  let userName: String?

  // Cloudant password
  let password: String?

  // Cloudant URL
  // Derived instance variable (for Cloudant)
  let url: String?

  private init(hostName: String, port: Int16, databaseName: String, secured: Bool, userName: String?, password: String?) {
      self.hostName = hostName
      self.port = port
      self.databaseName = databaseName
      self.userName = userName
      self.password = password
      self.secured = secured
      let httpProtocol = ConnectionProperties.deriveHttpProtocol(secured)
      if (userName != nil && password != nil) {
        self.url = "\(httpProtocol)://\(userName):\(password)\(hostName):\(port)"
      } else {
        self.url = "\(httpProtocol)://\(hostName):\(port)"
      }
  }

  public convenience init(userName: String, password: String, secured: Bool, databaseName: String) {
    let hostName = "\(userName).cloudant.com"
    let port: Int16 = 80
    // TODO: Switch to HTTPS once ETSocket supports it
    //let port: Int16 = 443
    //let url = "https://\(userName):\(password)\(hostName)"
    self.init(hostName: hostName, port: port, databaseName: databaseName, secured: false, userName: userName, password: password)
  }

  public convenience init(hostName: String, port: Int16, secured: Bool, databaseName: String) {
    self.init(hostName: hostName, port: port, databaseName: databaseName, secured: secured, userName: nil, password: nil)
  }

  static func deriveHttpProtocol(secured: Bool) -> String {
    let httpProtocol = (secured) ? "https" : "http"
    return httpProtocol
  }

}
