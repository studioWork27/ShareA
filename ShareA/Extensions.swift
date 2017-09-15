//
//  Extensions.swift
//  EventKitUITest
//
//  Created by Home on 3/5/17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import UIKit

extension DateFormatter {
    func loadDateString(dateString: String) -> Date? {
        self.timeZone = NSTimeZone.default
        self.dateFormat = "yyyy-MM-dd"
        return self.date(from: dateString)
    }

    func shortDateStr(date: Date) -> String {
        self.timeZone = NSTimeZone.default
        self.dateFormat = "M/d  h:mm a"//"E MMM d"// - h:mm  a"//"EEEE, dd MMM yyyy HH:mm:ss Z"
        return  self.string(from: date)
    }
}
