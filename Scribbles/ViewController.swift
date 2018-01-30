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
    guard let transform = sceneView.session.currentFrame?.camera.transform else { return }
    
    let anchor = ARAnchor(transform: transform)
    let drawingNode = DynamicGeometryNode(color: .red, lineWidth: 0.004)
    currentNode = drawingNode
    
    sceneView.session.add(anchor: anchor)
    nodes[anchor] = currentNode
    
    shouldDraw = true
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    shouldDraw = false
  }
  
  // MARK: Private
  
  private var sceneView: ARSCNView!
  private var currentNode: DynamicGeometryNode?
  private var nodes = [ARAnchor: DynamicGeometryNode]()
  private var shouldDraw = false
  
  private var carrotSession: CarrotSession<TextEvent>!
  
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
  
  private func centerOfScreen() -> SCNVector3 {
    let screenBounds = UIScreen.main.bounds
    let center = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
    let centerVec3 = SCNVector3Make(Float(center.x), Float(center.y), 0.99)
    return sceneView.unprojectPoint(centerVec3)
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
      }
    )
  }
  
  private func startCarrotSession() {
    carrotSession.start { state in
      print("Session state: \(state)")
    }
  }
  
  private func didReceiveMessage(_ result: MessageResult<DrawEvent>) {
    switch result {
    case let .success(message, endpoint?):
      switch endpoint {
      case "create":
        break
      case "add":
        break
      default:
        break
      }
    case let .error(error):
      print("ERROR: \(error)")
    }
  }
  
  // MARK: - ARSCNViewDelegate
  
  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    return nodes[anchor]
  }
 
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    guard shouldDraw, let currentNode = currentNode else { return }
    DispatchQueue.main.async {
      let vertice = self.centerOfScreen()
      currentNode.addVertice(vertice)
      // TODO: Send message to carrot that we've appended to a node's geometry
    }
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
