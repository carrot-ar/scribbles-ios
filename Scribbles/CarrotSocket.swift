//
//  CarrotSocket.swift
//  Scribbles
//
//  Created by Gonzalo Nunez on 10/17/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Carrot
import Foundation
import SocketRocket

public class CarrotSocket: NSObject, Socket {
  
  // MARK: Lifecycle
  
  public init(webSocket: SRWebSocket) {
    socket = webSocket
    super.init()
    socket.delegate = self
  }
  
  // MARK: Socket
  
  public weak var eventDelegate: SocketDelegate?
  
  public func open() {
    socket.open()
  }
  
  public func close() {
    socket.close()
  }
  
  public func send(data: Data) throws {
    socket.send(data)
  }
  
  // MARK: Private
  
  private let socket: SRWebSocket
}

extension CarrotSocket: SRWebSocketDelegate {
  
  public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
    eventDelegate?.socketDidOpen()
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
    eventDelegate?.socketDidClose(with: code, reason: reason, wasClean: wasClean)
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
    eventDelegate?.socketDidFail(with: error)
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    switch message {
    case let data as Data:
      eventDelegate?.socketDidReceive(data: data)
    case let message as String:
      eventDelegate?.socketDidReceive(data: Data(message.utf8))
    default:
      break
    }
  }
}
