//
//  Triangulator.swift
//  MetalSketch
//
//  Created by Gonzalo Nunez on 9/29/17.
//  Copyright © 2017 Zenun Software. All rights reserved.
//

import SceneKit

struct Triangulator {
  
  static func triangulate(points: [Vertex], thickness: Float) -> [SCNVector3] {
    var triangles = [Vertex]()
    for i in stride(from: 0, to: points.count-1, by: 1) {
      let p1 = points[i]
      let p2 = points[i+1]
      
      
      
      
      let direction = SCNVector3Direction(from: p1, to: p2)
      
      var n1 = direction
      n1.x *= -1
      swap(&n1.x, &n1.y)
      
      var n2 = direction
      n2.y *= -1
      swap(&n2.x, &n2.y)
      
      let halfThickness = thickness/2
      
      let c1 = p1 + n1*halfThickness
      let c2 = p1 + n2*halfThickness
      
      let c3 = p2 + n1*halfThickness
      let c4 = p2 + n2*halfThickness
      
      /*
        c3 p2 c4
         +--*--+
         |\    |
         | \   |
         |  \  |
         |   \ |
         |    \|
         +--*--+
         c1 p1 c2
      */
      
      triangles.append(contentsOf: [c1, c3, c2,
                                    c3, c4, c2])
    }
    return triangles
  }
}
