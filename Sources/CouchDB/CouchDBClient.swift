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
    print("In test method of couchDB client!")
    self.couchDB.create2(document, connProperties: connProperties, callback: { (id: String?, rev:String?, document: JSON?, error: NSError?) in
      if (error != nil) {

        print("CRAP!")
        print(error!.code)
        print(error!.domain)
        print(error!.userInfo)
      } else {
        print("Hmm.... did it just work?")
      }
    })
  }

  public func test2(document: JSON) {
    print("In test method of couchDB client!")
    self.couchDB.retrieve2("93868ba2bbea73154974a72eb3ef7144", connProperties: connProperties, callback: { (document: JSON?, error: NSError?) in
      if (error != nil) {

        print("CRAP!")
        print(error!.code)
        print(error!.domain)
        print(error!.userInfo)
      } else {
        print("Hmm.... did it just work?")
      }
    })
  }

}
