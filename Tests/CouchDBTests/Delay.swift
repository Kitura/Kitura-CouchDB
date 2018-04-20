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

import XCTest

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation

extension XCTestCase {
    func delay(time: Double = 1.0, _ work: @escaping () -> Void) {
        let start = DispatchSemaphore(value: 0)
        let end = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + time) {
            start.wait()
            work()
            end.signal()
        }
        start.signal()
        end.wait()
    }
}

