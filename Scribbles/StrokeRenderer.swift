//
//  StrokeRenderer.swift
//  Scribbles
//
//  Created by Gonzalo Nunez on 12/5/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import SceneKit
import simd

// MARK: - Vertex

struct Vertex {
  let position: float4
  let color: UIColor
  
  var floats: [Float] {
    return position + color.floats
  }
  
  static func direction(from: Vertex, to: Vertex) -> Vertex {
    assert(from.color == to.color)
    return Vertex(
      position: normalize(to.position - from.position),
      color: from.color)
  }
  
  func normalized() -> Vertex {
    let x = position.x
    let y = position.y
    let z = position.z
    let length = sqrtf(x*x + y*y + z*z)
    return Vertex(
      position: position / length,
      color: color)
  }
}

// MARK: - Stroke

class Stroke {
  
  // MARK: Lifecycle
  
  init(color: UIColor, thickness: Float = 0.02) {
    self.color = color
    self.thickness = thickness
  }
  
  // MARK: Internal
  
  var isEmpty: Bool {
    return vertices.isEmpty
  }
  
  var floats: [Float] {
    let triangulated = Triangulator.triangulate(points: vertices, thickness: thickness)
    return Array(triangulated.map { $0.floats }.joined())
  }
  
  func append(_ vertex: Vertex) {
    vertices.append(vertex)
  }
  
  func append(contentsOf vertices: [Vertex]) {
    self.vertices.append(contentsOf: vertices)
  }
  
  // MARK: Private
  
  private let color: UIColor
  private let thickness: Float // FIXME: per-point thickness
  private(set) var vertices = [Vertex]()
}

// MARK: - StrokeRenderer

class StrokeRenderer {
  
  // MARK: Lifecycle
  
  init() {
    vertexArray = PageAlignedContiguousArray<Float>()
    previousArraySpace = vertexArray.space
  }
  
  // MARK: Internal
  
  func startNewStroke(color: UIColor = .black) {
    if let currentStroke = currentStroke {
      oldStrokes.append(currentStroke)
    }
    currentStrokeStart = vertexArray.count
    currentStroke = Stroke(color: color)
  }
  
  func append(_ vertex: Vertex) {
    if currentStroke == nil {
      startNewStroke()
    }
    currentStroke?.append(vertex)
  }
  
  func append(contentsOf vertices: [Vertex]) {
    if currentStroke == nil {
      startNewStroke()
    }
    currentStroke?.append(contentsOf: vertices)
  }
  
  func render(with sceneRenderer: SCNSceneRenderer) throws {
    guard strokeCount > 0,
      let device = sceneRenderer.device,
      let renderEncoder = sceneRenderer.currentRenderCommandEncoder
    else {
      throw StrokeRendererError.metalNotSupported
    }
    
    renderEncoder.pushDebugGroup("DrawStrokes")
    
    updateBufferForCurrentStroke()
    
    if vertexBuffer == nil || vertexArray.space != previousArraySpace {
      vertexBuffer = device.makeBufferWithPageAlignedArray(vertexArray)!
    }
    
    // Set render command encoder state
    renderEncoder.setCullMode(.back)
    let renderPipelineState = try createRenderPipelineStateIfNeeded(with: device)
    renderEncoder.setRenderPipelineState(renderPipelineState)
    
    // Set any buffers fed into our render pipeline
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    
    // Draw old strokes
    if !oldStrokes.isEmpty {
      var offset = 0
      for stroke in oldStrokes {
        renderEncoder.setVertexBufferOffset(
          offset * MemoryLayout<Float>.stride,
          index: 0)
        renderEncoder.drawPrimitives(
          type: .triangle,
          vertexStart: 0,
          vertexCount: stroke.vertices.count)
        offset += stroke.floats.count
      }
    }
    
    // Draw current stroke
    if let currentStroke = currentStroke, !currentStroke.isEmpty {
      renderEncoder.setVertexBufferOffset(
        currentStrokeStart * MemoryLayout<Float>.stride,
        index: 0)
      renderEncoder.drawPrimitives(
        type: .triangle,
        vertexStart: 0,
        vertexCount: currentStroke.vertices.count)
    }
    
    renderEncoder.popDebugGroup()
  }
  
  // MARK: Private
  
  private var defaultLibrary: MTLLibrary?
  private var renderPipelineState: MTLRenderPipelineState?
  private var vertexBuffer: MTLBuffer?
  
  private var vertexArray: PageAlignedContiguousArray<Float>
  private var previousArraySpace: Int
  
  private var oldStrokes = [Stroke]()
  private var currentStroke: Stroke?
  private var currentStrokeStart = 0
  
  private var strokeCount: Int {
    return oldStrokes.count + (currentStroke != nil ? 1 : 0)
  }
  
  private func updateBufferForCurrentStroke() {
    if let currentStroke = currentStroke, !currentStroke.isEmpty {
      for (index, element) in currentStroke.floats.enumerated() {
        let globalIndex = currentStrokeStart + index
        if globalIndex < vertexArray.count {
          vertexArray[globalIndex] = element
        } else {
          vertexArray.append(element)
        }
      }
    }
  }
  
  private func createRenderPipelineStateIfNeeded(with device: MTLDevice) throws -> MTLRenderPipelineState {
    if let pipelineState = renderPipelineState {
      return pipelineState
    }
    guard let defaultLibrary = createMTLDefaultLibraryIfNeeded(with: device) else {
      throw StrokeRendererError.missingDefaultLibrary
    }
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = defaultLibrary.makeFunction(name: "basic_vertex")
    descriptor.fragmentFunction = defaultLibrary.makeFunction(name: "basic_fragment")
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    let pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    renderPipelineState = pipelineState
    return pipelineState
  }
  
  private func createMTLDefaultLibraryIfNeeded(with device: MTLDevice) -> MTLLibrary? {
    if let defaultLibrary = defaultLibrary {
      return defaultLibrary
    }
    let library = device.makeDefaultLibrary()
    defaultLibrary = library
    return library
  }
}

// MARK: - StrokeRendererError

enum StrokeRendererError: Error {
  case metalNotSupported
  case missingDefaultLibrary
}

// MARK: - UIColor+Floats

extension UIColor {
  var floats: [Float] {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return [r, g, b, a].map { Float($0) }
  }
}
