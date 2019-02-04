/**
 * Copyright IBM Corporation 2019
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

/// This struct represents the agreed upon fields and structure of a design documents.
/// The filters, lists, shows and updates fields objects are mapping of function name to string function source code.
/// The views mapping is the same except that values are objects with map and reduce (optional) keys which also contains functions source code.  
/// http://docs.couchdb.org/en/2.2.0/api/ddoc/common.html#put--db-_design-ddoc
public struct DesignDocument: Document {

    // MARK: Document fields

    /// The document ID.
    public let _id: String?

    /// The document revision.
    public let _rev: String?

    // MARK: Configuration

    /// The [Query Server key](http://docs.couchdb.org/en/2.2.0/query-server/index.html#query-server) to process design document functions.
    /// If this is nil, the language is assumed to be Javascript.
    public let language: String?

    /// The View’s default options.
    public let options: [String: Bool]?

    // MARK: Functions

    /// Filter functions definition.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#filterfun
    public let filters: [String: String]?

    /// List functions definition.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#listfun
    public let lists: [String: String]?

    /// Rewrite rules definition.
    public let rewrites: [String]?

    /// Show functions definition.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#showfun
    public let shows: [String: String]?

    /// Update functions definition.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#updatefun
    public let updates: [String: String]?

    /// Validate document update function source.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#vdufun
    public let validate_doc_update: String?

    /// View functions definition.
    /// http://docs.couchdb.org/en/2.2.0/ddocs/ddocs.html#viewfun
    public let views: [String: [String: String]]?

    // MARK: Initializer

    /// Initialize a `DesignDocument` instance.
    ///
    /// - parameter _id: The document ID.
    /// - parameter _rev: The document revision.
    /// - parameter language: The coding language.
    /// - parameter options: The View’s default options.
    /// - parameter filters: Filter functions definition.
    /// - parameter lists: Lists functions definition.
    /// - parameter rewrites: Rewrite rules definition.
    /// - parameter shows: Show functions definition.
    /// - parameter updates: Update functions definition.
    /// - parameter validate_doc_update: Validate document update function source.
    /// - parameter views: View functions definition.
    public init(_id: String? = nil,
            _rev: String? = nil,
            language: String? = nil,
            options: [String: Bool]? = nil,
            filters: [String: String]? = nil,
            lists: [String: String]? = nil,
            rewrites: [String]? = nil,
            shows: [String: String]? = nil,
            updates: [String: String]? = nil,
            validate_doc_update: String? = nil,
            views: [String: [String: String]]? = nil
    ) {
        self._id = _id
        self._rev = _rev
        self.language = language
        self.options = options
        self.filters = filters
        self.lists = lists
        self.rewrites = rewrites
        self.shows = shows
        self.updates = updates
        self.validate_doc_update = validate_doc_update
        self.views = views
    }
}
