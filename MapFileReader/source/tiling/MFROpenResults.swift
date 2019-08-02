/*
 * Copyright 2019 calimoto GmbH
 *
 * This file is from the OpenScienceMap project (http://www.opensciencemap.org)
 * was written in Java.
 * Here the file was translated by calimoto GmbH (https://calimoto.com)
 * with Swift.
 *
 * This program is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 A FileOpenResult is a simple DTO which is returned by IMapDatabase#open().
 */
public class MFROpenResult {

    /// Singleton for a FileOpenResult instance with {@code success=true}.
    static let SUCCESS : MFROpenResult = MFROpenResult()

    private let errorMessage : String?
    private let success : Bool

    /**
     - Parameter errorMessage: errorMessage a textual message describing the error, must not be null.
     */
    init(errorMessage : String?) throws {
        guard let msg = errorMessage, !msg.isEmpty else {
            throw MFRErrorHandler.IllegalArgumentException("no error message, but it´s required.")
        }

        self.success = false
        self.errorMessage = msg
    }

    /**
     The default constructor.
     */
    init() {
        self.success = true
        self.errorMessage = nil
    }

    /**
     - Return: A textual error description (might be null).
     */
    public func getErrorMessage() -> String {
        return self.errorMessage ?? "no error message!"
    }

    /**
     Return: True if the file could be opened successfully, false otherwise.
     */
    public func isSuccess() -> Bool {
        return self.success
    }

}
