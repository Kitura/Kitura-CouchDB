import Foundation
import SwiftyJSON

public class CouchDBClient {

  public let connProperties: ConnectionProperties
  private let couchDB: CouchDB

  public init(connectionProperties: ConnectionProperties) {
    self.connProperties = connectionProperties
    //TODO - fix this
    self.couchDB = CouchDB(ipAddress: connectionProperties.hostName,
      port: connectionProperties.port, dbName: connectionProperties.databaseName)
    //TODO
  }

  //TODO
  public func test(document: JSON) {
    print("HERE!")
    self.couchDB.create(document, callback: { (id: String?, rev:String?, document: JSON?, error: NSError?) in
      if (error != nil) {
        print("CRAP!")
      } else {
        print("Hmm.... did it just work?")
      }
    })

  }

}
