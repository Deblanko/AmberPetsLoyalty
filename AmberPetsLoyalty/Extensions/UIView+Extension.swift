//
//  UIView+Extension.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/25/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit


extension UIView {
    
    func roundButtons(radius : CGFloat = 5.0) {
        let buttons = self.subviews.compactMap{$0 as? UIButton}
        for button in buttons {
            button.layer.cornerRadius = radius
        }
    }
    
}
