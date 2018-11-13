/**
 * Copyright IBM Corporation 2018
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

/// A protocol defining the mandatory fields for a user document retrieved from a CouchDB database.
/// http://docs.couchdb.org/en/2.2.0/intro/security.html#users-documents
public protocol RetrievedUserDocument: Document {
    /// A PBKDF2 key.
    var derived_key: String? { get }

    /// User’s name aka login.
    var name: String { get }

    /// A list of user roles.
    /// CouchDB doesn’t provide any built-in roles, so you define your own depending on your needs.
    var roles: [String] { get }

    /// Hashed password with salt. Used for "simple" password_scheme.
    var password_sha: String? { get }

    /// Password hashing scheme. May be "simple" or "pbkdf2".
    var password_scheme: String { get }

    /// Hash salt. Used for "simple" password_scheme.
    var salt: String? { get }

    /// Document type. Constantly has the value "user"
    var type: String { get }
}
