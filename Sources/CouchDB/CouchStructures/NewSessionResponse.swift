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

/// A struct representing the server response when creating a new session.  
/// http://docs.couchdb.org/en/stable/api/server/authn.html#post--_session
public struct NewSessionResponse: Codable {

    /// Operation status.
    public let ok: Bool

    /// Username.
    public let name: String

    /// List of user roles
    public let roles: [String]
}
