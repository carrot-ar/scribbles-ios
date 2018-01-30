//
//  DrawEvent.swift
//  Scribbles
//
//  Created by Gonzalo Nunez on 1/30/18.
//  Copyright © 2018 carrot. All rights reserved.
//

import CoreGraphics
import Foundation

enum DrawEvent: Codable {
  case created(VertexCreated)
  case added(VertexAdded)
}

struct VertexCreated: Codable {
  var point: [Int]
}

struct VertexAdded: Codable {
  var point: [Int]
}
