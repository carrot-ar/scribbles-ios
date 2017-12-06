//
//  Triangulator.swift
//  MetalSketch
//
//  Created by Gonzalo Nunez on 9/29/17.
//  Copyright © 2017 Zenun Software. All rights reserved.
//

import SceneKit

struct Triangulator {
  
  static func triangulate(points: [Vertex], thickness: Float) -> [Vertex] {
    var triangles = [Vertex]()
    for i in stride(from: 0, to: points.count-1, by: 1) {
      let p1 = points[i]
      let p2 = points[i+1]
      
      let direction = Vertex.direction(from: p1, to: p2).position
      
      var n1 = direction
      n1.x *= -1
      let tempn1 = n1.x
      n1.x = n1.y
      n1.y = tempn1
      
      var n2 = direction
      n2.y *= -1
      let tempn2 = n2.x
      n2.x = n2.y
      n2.y = tempn2
      
      let halfThickness = thickness/2
      
      let c1 = Vertex(position: p1.position + n1*halfThickness, color: p1.color)
      let c2 = Vertex(position: p1.position + n2*halfThickness, color: p1.color)
      
      let c3 = Vertex(position: p2.position + n1*halfThickness, color: p1.color)
      let c4 = Vertex(position: p2.position + n2*halfThickness, color: p1.color)
      
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
