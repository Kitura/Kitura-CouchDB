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

/// A struct representing the information about the authenticated user
/// that is returned when a GET request is made to `_session`.
/// http://docs.couchdb.org/en/stable/api/server/authn.html#get--_session
public struct UserSessionInformation: Codable {

    /// Operation status.
    public let ok: Bool

    /// The user context object.
    public let userCtx: UserContextObject

    /// The session info.
    public let info: SessionInfo

    /// The users information for the current session.  
    /// http://docs.couchdb.org/en/stable/json-structure.html#user-context-object
    public struct UserContextObject: Codable {

        /// Database name.
        public let db: String

        /// User name.
        public let name: String

        /// List of user roles.
        public let roles: [String]
    }

    /// The authentication information about the current session.
    public struct SessionInfo: Codable {

        /// The authentication method.
        public let authenticated: String

        /// The database used for authentication.
        public let authentication_db: String

        /// The Authentication handlers.
        public let authentication_handlers: [String]
    }
}
