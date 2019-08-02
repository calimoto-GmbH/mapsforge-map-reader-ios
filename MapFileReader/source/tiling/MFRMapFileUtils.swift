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

public class MFRMapFileUtils {
    /**
     Extracts substring of preferred language from multilingual string.<br/>
     Example multilingual string: "Base\ren\bEnglish\rjp\bJapan\rzh_py\bPin-yin".

     Use '\r' delimiter among names and '\b' delimiter between each language and name.
     */
    static func extract(s: String?, language: String) -> String? {
        guard let s = s, !s.isEmpty else {
            return nil
        }

        let langNames: [String] = s.components(separatedBy: "\r")

        guard langNames.count > 0 else {
            return nil
        }

        if language.isEmpty {
            return langNames[0]
        }

        var fallback: String? = nil
        for i in 1 ..< langNames.count
        {
            let langName: [String] = langNames[i].components(separatedBy: "\u{8}") //\u{8} == \b
            if (langName.count != 2) {
                continue
            }

            // Perfect match
            if (langName[0].lowercased().contains(language.lowercased())) {
                return langName[1]
            }

            // Fall back to base, e.g. zh-min-lan -> zh
//            if (fallback == null && !langName[0].contains("-") && (language.contains("-") || language.contains("_"))
//                && language.toLowerCase(Locale.ENGLISH).startsWith(langName[0].toLowerCase(Locale.ENGLISH))) {
//                fallback = langName[1]
//            }
            printN("fallback : \(fallback ?? "no fallback")")
            printN("language : \(language)")
            printN("langNames : \(langName)")
            printN("language.lowercased(with: Locale(identifier: \"en\")) : \(language.lowercased(with: Locale(identifier: "en")))")
            printN("language.lowercased(with: Locale(identifier: \"en\")).startsWith(string: langName[0].lowercased(with: Locale(identifier: \"en\"))) : \(language.lowercased(with: Locale(identifier: "en")).startsWith(string: langName[0].lowercased(with: Locale(identifier: "en"))))")
            if (fallback == nil && !langName[0].contains("-") && (language.contains("-") || language.contains("_"))
                && language.lowercased(with: Locale(identifier: "en")).startsWith(string: langName[0].lowercased(with: Locale(identifier: "en")))) {
                fallback = langName[1]
            }
        }
        return (fallback != nil) ? fallback : langNames[0]
    }

    /// The property is a flag to show logs in the console during the tile requests.
    /// - Note: The console output is only active in the development mode.
    public static var showLogs = false

    private init() {
    }
}

func printN(_ item: Any?) {
    if let item = item, MFRMapFileUtils.showLogs {
        #if DEBUG
        print("[MapFileReader]: \(item)")
        #endif
    }
}
