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

/// A Default implementation of the `NewUserDocument` protocol with no custom user fields defined.
public struct DefaultNewUserDocument: NewUserDocument {

    /// The unique immutable username that will be used to log in.
    /// If the name already exists, the old user will be replaced with this new user.
    public var name: String

    /// The password for the user in plaintext.
    /// The CouchDB authentication database will replaces this with the secured hash.
    public var password: String

    /// A list of user roles.
    /// CouchDB doesn’t provide any built-in roles, so you define your own depending on your needs.
    public var roles: [String]

    /// Initialize a `DefaultNewUserDocument`.
    ///
    /// - parameter name: The username that will be used to log in.
    /// - parameter password: The password for the user in plaintext.
    /// - parameter roles: A list of user roles.
    public init(name: String, password: String, roles: [String]) {
        self.name = name
        self.roles = roles
        self.password = password
    }
}
