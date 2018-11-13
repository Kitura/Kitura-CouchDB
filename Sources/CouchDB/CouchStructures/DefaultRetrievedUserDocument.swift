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

/// Default implementation of the `RetrievedUserDocument` protocol with no custom user fields defined.
public struct DefaultRetrievedUserDocument: RetrievedUserDocument {
    /// The Document ID. Contains user’s name with the prefix "org.couchdb.user:"
    public var _id: String?

    /// The Document revision.
    public var _rev: String?

    /// A PBKDF2 key.
    public var derived_key: String?

    /// User’s name aka login.
    public var name: String

    /// A list of user roles.
    public var roles: [String]

    /// Hashed password with salt. Used for "simple" password_scheme.
    public var password_sha: String?

    /// Password hashing scheme. May be "simple" or "pbkdf2".
    public var password_scheme: String

    /// Hash salt. Used for "simple" password_scheme.
    public var salt: String?

    /// Document type. Constantly has the value "user"
    public var type: String
}
