//
//  TextEvent.swift
//  Scribbles
//
//  Created by Gonzalo Nunez on 1/30/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import CoreGraphics
import Foundation

struct TextEvent: Codable {
  var text: String
  var extrusionDepth: CGFloat
}
