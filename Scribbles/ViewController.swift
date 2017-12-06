//
//  ViewController.swift
//  Scribbles
//
//  Created by Gonzalo Nunez on 12/5/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import ARKit
import Carrot
import SceneKit
import SocketRocket
import UIKit

// MARK: - ViewController

class ViewController: UIViewController, ARSCNViewDelegate, SCNSceneRendererDelegate {
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpSceneView()
    setUpSceneViewConstraints()
    setUpScene()
    setUpCarrotSession()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let configuration = ARWorldTrackingConfiguration()
    configuration.worldAlignment = .gravityAndHeading
    sceneView.session.run(configuration)
    
    startCarrotSession()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    sceneView.session.pause()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    shouldDraw = true
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    shouldDraw = false
  }
  
  // MARK: Private
  
  private var sceneView: ARSCNView!
  private var events = [ARAnchor: TextEvent]()
  private var carrotSession: CarrotSession<TextEvent>!
  private var strokeRenderer = StrokeRenderer()
  private var shouldDraw = false {
    didSet {
      let wasDrawing = oldValue
      if shouldDraw && !wasDrawing {
        strokeRenderer.startNewStroke()
      }
    }
  }
  
  private func setUpSceneView() {
    sceneView = ARSCNView(frame: view.frame)
    sceneView.delegate = self
    sceneView.showsStatistics = true
    view.addSubview(sceneView)
  }
  
  private func setUpScene() {
    sceneView.scene = SCNScene()
  }
  
  private func setUpSceneViewConstraints() {
    sceneView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      sceneView.topAnchor.constraint(equalTo: view.topAnchor),
      sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      sceneView.leftAnchor.constraint(equalTo: view.leftAnchor),
      sceneView.rightAnchor.constraint(equalTo: view.rightAnchor)
    ])
  }
  
  // MARK: Carrot
  
  private func setUpCarrotSession() {
    let socket = SRWebSocket(url: URL(string: "http://235089d6.ngrok.io/ws")!)!
    let carrotSocket = CarrotSocket(webSocket: socket)
    carrotSession = CarrotSession(
      socket: carrotSocket,
      currentTransform: { [weak self] in
        return self?.sceneView.session.currentFrame?.camera.transform
      },
      messageHandler: didReceiveMessage,
      errorHandler: { _, error in
        print("ERROR: \(error)")
        return nil
      }
    )
  }
  
  private func startCarrotSession() {
    carrotSession.start { state in
      print("Session state: \(state)")
    }
  }
  
  func didReceiveMessage(_ result: Result<Message<TextEvent>>, endpoint: String?) {
    switch result {
    case let .success(message):
      guard let position = message.location else { return }
      
      var transform = matrix_identity_float4x4
      transform.columns.3.x = Float(position.x)
      transform.columns.3.y = Float(position.y)
      transform.columns.3.z = Float(position.z)
      let anchor = ARAnchor(transform: transform)
      
      events[anchor] = message.object
      sceneView.session.add(anchor: anchor)
    case let .error(error):
      print("ERROR: \(error)")
    }
  }
  
  // MARK: - ARSCNViewDelegate
  
  /*
  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    guard let event = events[anchor] else {
      return nil
    }
    
    let text = SCNText(
      string: event.text,
      extrusionDepth: event.extrusionDepth)
    
    return SCNNode(geometry: text)
  }
  */
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    guard carrotSession.state.isAuthenticated, shouldDraw else { return }
    
    let offset = sceneView.session.currentFrame!.camera.transform.columns.3
    let vertex = Vertex(position: offset, color: .red)
    strokeRenderer.append(vertex)
    
    do {
      try strokeRenderer.render(with: renderer)
    } catch {
      print("ERROR: \(error)")
    }
    
    /*
    let event = TextEvent(
      text: "🥕",
      extrusionDepth: 3)
    
    let message = Message(
      location: Location3D(x: x, y: y, z: z),
      object: event)
    
    do {
      try carrotSession.send(message: message, to: "draw")
    } catch {
      print("ERROR: \(error)")
    }
    */
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user
    
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
  }
}

// MARK: - TextEvent

struct TextEvent: Codable {
  var text: String
  var extrusionDepth: CGFloat
}
