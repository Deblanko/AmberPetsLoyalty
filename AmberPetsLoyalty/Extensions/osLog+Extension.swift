//
//  osLog+Extension.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/17/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.deblanko.amberpetsloyalty"

    /// Logs app delegate view
    static let appDelegate = OSLog(subsystem: subsystem, category: "appDelegate")
    /// Logs app Data Model view
    static let dataModel = OSLog(subsystem: subsystem, category: "dataModel")
    /// Logs initial view
    static let initialView = OSLog(subsystem: subsystem, category: "initialView")
    /// Logs admin view
    static let adminView = OSLog(subsystem: subsystem, category: "adminView")
    /// Logs allCustomers view
    static let allCustomersView = OSLog(subsystem: subsystem, category: "allCustomersView")
    /// Logs allCustomers view
    static let vouchersView = OSLog(subsystem: subsystem, category: "vouchersView")
    /// Logs customer view
    static let customerView = OSLog(subsystem: subsystem, category: "customerView")

}
