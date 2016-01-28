/**
 * Builder class for DBConnectionProperties.
 *
 * @author Ricardo Olivieri
 */

import Foundation

public class CouchDBClientBuilder {

  public enum Error: ErrorType {
    case MissingRequiredParameters
  }

  // Hostname or IP address to the CouchDB server
  private var hostName: String?

  // Port number where CouchDB server is listening for incoming connections
  private var port: Int16?

  // The database name
  private var databaseName: String?

  // Authentication credentials to access Cloudant
  // Cloudant username
  private var userName: String?

  // Cloudant password
  private var password: String?

  public init() {
    // Default constructor
  }

  public func hostName(hostName: String) -> CouchDBClientBuilder {
    self.hostName = hostName
    return self
  }

  public func port(port: Int16) -> CouchDBClientBuilder {
    self.port = port
    return self
  }

  public func databaseName(databaseName: String) -> CouchDBClientBuilder {
    self.databaseName = databaseName
    return self
  }

  public func userName(userName: String) -> CouchDBClientBuilder {
    self.userName = userName
    return self
  }

  public func password(password: String) -> CouchDBClientBuilder {
    self.password = password
    return self
  }

  public func build() throws -> CouchDBClient {
    let connProperties: ConnectionProperties?

    // Create CouchDBClient instance and return it
    if (self.hostName != nil && self.port != nil && self.databaseName != nil) {
      connProperties = ConnectionProperties(hostName: self.hostName!,
        port: self.port!, databaseName: self.databaseName!)
    } else if (self.userName != nil && self.password != nil) {
      connProperties = ConnectionProperties(userName: self.userName!,
        password: self.password!, databaseName: self.databaseName!)
    } else {
      throw Error.MissingRequiredParameters
    }

    let couchDBClient = CouchDBClient(connectionProperties: connProperties!)
    return couchDBClient
  }

}
