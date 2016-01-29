//
//  Database.swift
//  PhoenixCouchDB
//
//  Authors: Ira Rosen, Ricardo Olivieri
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import SwiftyJSON
import net

public class Database {

  public enum StaleOptions {
    case OK
    case UpdateAfter
  }

  public enum QueryParameters {
    case Conflicts (Bool)
    case Descending (Bool)
    case EndKey (AnyObject)
    case EndKeyDocID (String)
    case Group (Bool)
    case GroupLevel (Int)
    case IncludeDocs (Bool)
    case Attachments (Bool)
    case AttachmentEncodingInfo (Bool)
    case InclusiveEnd(Bool)
    case Limit (Int)
    case Reduce (Bool)
    case Skip (Int)
    case Stale (StaleOptions)
    case StartKey (AnyObject)
    case StartKeyDocID (String)
    case UpdateSequence (Bool)
    case Keys ([AnyObject])
  }

  public static let Error = [
    INTERNAL_ERROR: "Internal Error",
    INVALID_DOCUMENT: "Invalid Document Body",
    INVALID_ATTACHMENT: "Invalid attachment"
  ]

  public static let INTERNAL_ERROR = 0
  public static let INVALID_DOCUMENT = 1
  public static let INVALID_ATTACHMENT = 2

  public let name : String
  public let escapedName: String
  public let connProperties: ConnectionProperties

  private static func createQueryParamForArray(array: Array<AnyObject>) -> String {
    var result = "["
    var comma = ""
    for element in array {
      result += "\(comma)\(element)"
      comma = ","
    }
    return result + "]"
  }

  public init (connProperties: ConnectionProperties, dbName: String) {
    self.name = dbName
    self.escapedName = Http.escapeUrl(name)
    self.connProperties = connProperties
  }

  public func retrieve(id: String, connProperties: ConnectionProperties, callback: (JSON?, NSError?) -> ())   {
    let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET", path: "/\(escapedName)/\(Http.escapeUrl(id))", hasBody: false)
    var document: JSON?
    let req = Http.request(requestOptions) { response in
      var error: NSError?
      if let response = response {
        document = CouchDBUtils.getBodyAsJson(response)
        if response.statusCode != HttpStatusCode.OK {
          error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: id, rev: nil)
        }
      }
      else {
        error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: id, rev: nil)
      }
      callback(document, error)
    }
    req.end()
  }

  public func update(id: String, rev: String, document: JSON, callback: (rev:String?, document: JSON?, error: NSError?) -> ())   {
    if let requestBody = document.rawString() {
      var doc: JSON?
      var revision: String?
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(Http.escapeUrl(id))?rev=\(Http.escapeUrl(rev))", hasBody: true)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        if let response = response {
          doc = CouchDBUtils.getBodyAsJson(response)
          revision = doc?["rev"].string
          if response.statusCode != HttpStatusCode.CREATED && response.statusCode != HttpStatusCode.ACCEPTED {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: id, rev: rev)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: id, rev: rev)
        }
        callback(rev: revision, document: doc, error: error)
      }
      req.end(requestBody)
    }
    else {
      callback(rev: nil, document: nil, error: CouchDBUtils.createError(Database.INVALID_DOCUMENT, id: id, rev: rev))
    }
  }

  public func create(document: JSON, connProperties: ConnectionProperties, callback: (id: String?, rev:String?, document: JSON?, error: NSError?) -> ())   {
    if let requestBody = document.rawString() {
      var id: String?
      var doc: JSON?
      var revision: String?
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "POST", path: "/\(escapedName)", hasBody: true)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        if let response = response {
          doc = CouchDBUtils.getBodyAsJson(response)
          id = doc?["id"].string
          revision = doc?["rev"].string
          if response.statusCode != HttpStatusCode.CREATED && response.statusCode != HttpStatusCode.ACCEPTED {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: nil, rev: nil)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
        }
        callback(id: id, rev: revision, document: doc, error: error)
      }
      req.end(requestBody)
    }
    else {
      callback(id: nil, rev: nil, document: nil, error: CouchDBUtils.createError(Database.INVALID_DOCUMENT, id: nil, rev: nil))
    }
  }

  public func delete(id: String, rev: String, failOnNotFound: Bool = false, callback: (NSError?) -> ())   {
    let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(Http.escapeUrl(id))?rev=\(Http.escapeUrl(rev))", hasBody: false)
    let req = Http.request(requestOptions) { response in
      var error: NSError?
      if let response = response {
        if (response.statusCode != HttpStatusCode.OK && response.statusCode != HttpStatusCode.ACCEPTED)
          || (response.statusCode == HttpStatusCode.NOT_FOUND && failOnNotFound) {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: id, rev: rev)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: id, rev: rev)
        }
        callback(error)
      }
      req.end()
    }
  public func queryByView(view: String, ofDesign design: String, usingParameters params: [Database.QueryParameters], callback: (JSON?, NSError?) -> ()) {
    var paramString = ""
    var keys: [AnyObject]?

    for param in params {
      switch param {
        case .Conflicts (let value):
          paramString += "conflicts=\(value)&"
        case .Descending (let value):
            paramString += "descending=\(value)&"
        case .EndKey (let value):
          if value is String {
            paramString += "endkey=\"\(Http.escapeUrl(value as! String))\"&"
          }
          else if value is Array<AnyObject> {
            paramString += "endkey=" + Database.createQueryParamForArray(value as! Array<AnyObject>) + "&"
          }
        case .EndKeyDocID (let value):
          paramString += "endkey_docid=\"\(Http.escapeUrl(value))\"&"
        case .Group (let value):
          paramString += "group=\(value)&"
        case .GroupLevel (let value):
          paramString += "group_level=\(value)&"
        case .IncludeDocs (let value):
          paramString += "include_docs=\(value)&"
        case .Attachments (let value):
          paramString += "attachments=\(value)&"
        case .AttachmentEncodingInfo (let value):
          paramString += "att_encoding_info=\(value)&"
        case .InclusiveEnd (let value):
          paramString += "inclusive_end=\(value)&"
        case .Limit (let value):
          paramString += "limit=\(value)&"
        case .Reduce (let value):
          paramString += "reduce=\(value)&"
        case .Skip (let value):
          paramString += "skip=\(value)&"
        case .Stale (let value):
          paramString += "stale=\"\(value)\"&"
        case .StartKey (let value):
          if value is String {
            paramString += "startkey=\"\(Http.escapeUrl(value as! String))\"&"
          } else if value is Array<AnyObject> {
            paramString += "startkey=" + Database.createQueryParamForArray(value as! Array<AnyObject>) + "&"
          }
        case .StartKeyDocID (let value):
          paramString += "start_key_doc_id=\"\(Http.escapeUrl(value))\"&"
        case .UpdateSequence (let value):
          paramString += "update_seq=\(value)&"
        case .Keys (let value):
          if value.count == 1 {
            if value[0] is String {
              paramString += "key=\"\(Http.escapeUrl(value[0] as! String))\"&"
            }
            else if value[0] is Array<AnyObject> {
              paramString += "key=" + Database.createQueryParamForArray(value[0] as! Array<AnyObject>) + "&"
            }
          }
          else {
            keys = value
          }
      }
    }

    if paramString.characters.count > 0 {
      paramString = "?" + String(paramString.characters.dropLast())
    }

    var method = "GET"
    var hasBody = false
    var body: JSON?
    if let keys = keys {
      method = "POST"
      hasBody = true
      body = JSON(["keys": keys])
    }

    let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: method, path: "/\(escapedName)/_design/\(Http.escapeUrl(design))/_view/\(Http.escapeUrl(view))\(paramString)", hasBody: hasBody)
    var document: JSON?
    let req = Http.request(requestOptions) { response in
      var error: NSError?
      if let response = response {
        document = CouchDBUtils.getBodyAsJson(response)
        if response.statusCode != HttpStatusCode.OK {
          error = CouchDBUtils.createError(response.statusCode, errorDesc: document, id: nil, rev: nil)
        }
      }
      else {
        error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
      }
      callback(document, error)
    }

    if let _ = body, let bodyAsString = body!.rawString() {
      req.end(bodyAsString)
    }
    else {
      req.end()
    }
  }

  public func createDesign(designName: String, document: JSON, callback: (JSON?, NSError?) -> ())   {
    if let requestBody = document.rawString() {
      var doc: JSON?
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/_design/\(Http.escapeUrl(designName))", hasBody: true)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        if let response = response {
          doc = CouchDBUtils.getBodyAsJson(response)
          if response.statusCode != HttpStatusCode.CREATED && response.statusCode != HttpStatusCode.ACCEPTED {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: nil, rev: nil)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: nil, rev: nil)
        }
        callback(doc, error)
      }
      req.end(requestBody)
    }
    else {
      callback(nil, CouchDBUtils.createError(Database.INVALID_DOCUMENT, id: designName, rev: nil))
    }
  }

  public func deleteDesign(designName: String, revision: String, failOnNotFound: Bool = false, callback: (NSError?) -> ())   {
    let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/_design/\(Http.escapeUrl(designName))?rev=\(Http.escapeUrl(revision))", hasBody: false)
    let req = Http.request(requestOptions) { response in
      var error: NSError?
      if let response = response {
        if (response.statusCode != HttpStatusCode.OK && response.statusCode != HttpStatusCode.ACCEPTED)
          || (response.statusCode == HttpStatusCode.NOT_FOUND && failOnNotFound) {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: designName, rev: revision)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: designName, rev: revision)
        }
        callback(error)
      }
      req.end()
    }

    public func createAttachment(docId: String, docRevison: String, attachmentName: String, attachmentData: NSData, contentType: String, callback: (rev:String?, document: JSON?, error: NSError?) -> ())   {
      var doc: JSON?
      var revision: String?
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "PUT", path: "/\(escapedName)/\(Http.escapeUrl(docId))/\(Http.escapeUrl(attachmentName))?rev=\(Http.escapeUrl(docRevison))", hasBody: true, contentType: contentType)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        if let response = response {
          doc = CouchDBUtils.getBodyAsJson(response)
          revision = doc?["rev"].string
          if response.statusCode != HttpStatusCode.CREATED && response.statusCode != HttpStatusCode.ACCEPTED {
            error = CouchDBUtils.createError(response.statusCode, errorDesc: doc, id: docId, rev: docRevison)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: docId, rev: docRevison)
        }
        callback(rev: revision, document: doc, error: error)
      }
      req.end(attachmentData)
    }

    public func retrieveAttachment(docId: String, attachmentName: String, callback: (NSData?, NSError?, String?) -> ())   {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "GET", path: "/\(escapedName)/\(Http.escapeUrl(docId))/\(Http.escapeUrl(attachmentName))", hasBody: false)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        var attachment: NSData?
        var contentType: String?
        if let response = response {
          attachment = CouchDBUtils.getBodyAsNSData(response)
          contentType = response.headers["Content-Type"]
          if response.statusCode != HttpStatusCode.OK {
            error = CouchDBUtils.createError(response.statusCode, id: docId, rev: nil)
          }
        }
        else {
          error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: docId, rev: nil)
        }
        callback(attachment, error, contentType)
      }
      req.end()
    }

    public func deleteAttachment(docId: String, docRevison: String, attachmentName: String, failOnNotFound: Bool = false, callback: (NSError?) -> ())   {
      let requestOptions = CouchDBUtils.prepareRequest(connProperties, method: "DELETE", path: "/\(escapedName)/\(Http.escapeUrl(docId))/\(Http.escapeUrl(attachmentName))?rev=\(Http.escapeUrl(docRevison))", hasBody: false)
      let req = Http.request(requestOptions) { response in
        var error: NSError?
        if let response = response {
          if (response.statusCode != HttpStatusCode.OK && response.statusCode != HttpStatusCode.ACCEPTED)
            || (response.statusCode == HttpStatusCode.NOT_FOUND && failOnNotFound) {
              error = CouchDBUtils.createError(response.statusCode, errorDesc: CouchDBUtils.getBodyAsJson(response), id: docId, rev: docRevison)
            }
          }
          else {
            error = CouchDBUtils.createError(Database.INTERNAL_ERROR, id: docId, rev: docRevison)
          }
          callback(error)
        }
        req.end()
      }
    }
