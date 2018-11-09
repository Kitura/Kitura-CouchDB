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

/// A protocol defining the required fields to create a new user document or update an existing user document.
/// http://docs.couchdb.org/en/2.2.0/intro/security.html#creating-a-new-user
public protocol NewUserDocument: Codable {

    /// The unique immutable username that will be used to log in.
    /// If the name already exists, the old user will be replaced with this new user.
    var name: String { get }

    /// The password for the user in plaintext.
    /// The CouchDB authentication database will replaces this with the secured hash.
    var password: String { get }

    /// A list of user roles.
    /// CouchDB doesn’t provide any built-in roles, so you define your own depending on your needs.
    var roles: [String] { get }

    /// Document type.
    var type: String { get }

}
public extension NewUserDocument {
    /// The Default value of type is "user".
    var type: String {
        return "user"
    }
}
