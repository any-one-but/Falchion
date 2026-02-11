//
//  Item.swift
//  falchion
//
//  Created by Jo Walsh on 2/11/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
