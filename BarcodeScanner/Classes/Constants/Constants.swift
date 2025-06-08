//
//  Constants.swift
//  BarcodeScanner
//
//  Created by Nirzar Gandhi on 02/06/25.
//

import Foundation
import UIKit

let BASEWIDTH = 375.0
let SCREENSIZE: CGRect      = UIScreen.main.bounds
let SCREENWIDTH             = UIScreen.main.bounds.width
let SCREENHEIGHT            = UIScreen.main.bounds.height
let WINDOWSCENE             = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
let STATUSBARHEIGHT         = WINDOWSCENE?.statusBarManager?.statusBarFrame.size.height
var NAVBARHEIGHT            = 44.0

let APPDELEOBJ  = UIApplication.shared.delegate as! AppDelegate

struct Constants {
    
    struct Storyboard {
        
        static let Main = "Main"
    }
    
    struct Generic {
        
        static let ERROR_MESSAGE = "Something went wrong. Please try again"
    }
}
