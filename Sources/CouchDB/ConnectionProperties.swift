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

  // Authentication credentials to access Cloudant
  // Cloudant username
  let userName: String?

  // Cloudant password
  let password: String?

  // Cloudant URL
  // Derived instance variable (for Cloudant)
  let url: String?

  private init(hostName: String, port: Int16, databaseName: String, userName: String?, password: String?, url: String?) {
      self.hostName = hostName
      self.port = port
      self.databaseName = databaseName
      self.userName = userName
      self.password = password
      self.url = url
  }

  public convenience init(userName: String, password: String, databaseName: String) {
    let hostName = "\(userName).cloudant.com"
    let port: Int16 = 443
    let url = "https://\(hostName)"
    self.init(hostName: hostName, port: port, databaseName: databaseName, userName: userName, password: password, url: url)
  }

  public convenience init(hostName: String, port: Int16, databaseName: String) {
      self.init(hostName: hostName, port: port, databaseName: databaseName, userName: nil, password: nil, url: nil)
  }

}
