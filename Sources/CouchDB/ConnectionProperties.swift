//
//  ConnectionProperties.swift
//  PhoenixCouchDB
//  Contains configuration properties for connecting to CouchDB or Cloudant instance.
//
//  Authors: Ricardo Olivieri
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

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

  private init(hostName: String, port: Int16, secured: Bool, userName: String?, password: String?) {
      self.hostName = hostName
      self.port = port
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

  public convenience init(userName: String, password: String, secured: Bool) {
    let hostName = "\(userName).cloudant.com"
    let port: Int16 = secured ? 443 : 80
    self.init(hostName: hostName, port: port, secured: false, userName: userName, password: password)
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
