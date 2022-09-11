//
//  Date+FormattedOutput.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 05/09/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import Foundation

public extension Optional where Wrapped == Date {
    var prettyOutput : String {
        guard let date = self else {
            return "Never"
        }
        let dateFormatter = DateFormatter()
        // Set Date/Time Style
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
}
