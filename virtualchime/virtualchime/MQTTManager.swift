//
//  MQTTManager.swift
//  virtualchime
//
//  Created by Timo Weiß on 30.08.24.
//

import Foundation
import CocoaMQTT
import Combine

final class MQTTManager: ObservableObject {
    private var mqttClient: CocoaMQTT?
    private var identifier: String!
    private var host: String!
    private var topic: String!
    private var username: String!
    private var password: String!

    var mqttUsername: String {
        return username ?? ""
    }

    var mqttPassword: String {
        return password ?? ""
    }

    @Published var currentAppState = MQTTAppState()
    private var anyCancellable: AnyCancellable?

    private init() {
        anyCancellable = currentAppState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        loadSettings() // Load saved settings on initialization
    }

    private static let _shared = MQTTManager()

    class func shared() -> MQTTManager {
        return _shared
    }

    func initializeMQTT(host: String, identifier: String, username: String? = nil, password: String? = nil) {
        if mqttClient != nil {
            mqttClient = nil
        }
        self.identifier = identifier
        self.host = host
        self.username = username
        self.password = password
        saveSettings() // Save settings whenever they are initialized

        let clientID = "CocoaMQTT-\(identifier)-" + String(ProcessInfo().processIdentifier)

        mqttClient = CocoaMQTT(clientID: clientID, host: host, port: 1883)
        if let finalUsername = self.username, let finalPassword = self.password {
            mqttClient?.username = finalUsername
            mqttClient?.password = finalPassword
        }
        mqttClient?.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
        mqttClient?.keepAlive = 60
        mqttClient?.delegate = self
    }

    func connect() {
        if let success = mqttClient?.connect(), success {
            currentAppState.setAppConnectionState(state: .connecting)
        } else {
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }

    func disconnect() {
        mqttClient?.disconnect()
        currentAppState.setAppConnectionState(state: .disconnected)
    }

    func subscribe(topic: String) {
        self.topic = topic
        mqttClient?.subscribe(topic, qos: .qos1)
    }

    func publish(with message: String) {
        mqttClient?.publish(topic, withString: message, qos: .qos1)
    }

    func unSubscribe(topic: String) {
        mqttClient?.unsubscribe(topic)
    }

    func unSubscribeFromCurrentTopic() {
        mqttClient?.unsubscribe(topic)
    }

    func currentHost() -> String? {
        return host
    }

    func isSubscribed() -> Bool {
        return currentAppState.appConnectionState.isSubscribed
    }

    func isConnected() -> Bool {
        return currentAppState.appConnectionState.isConnected
    }

    func connectionStateMessage() -> String {
        return currentAppState.appConnectionState.description
    }

    // MARK: - Save and Load Settings

    private func saveSettings() {
        UserDefaults.standard.set(host, forKey: "mqttHost")
        UserDefaults.standard.set(username, forKey: "mqttUsername")
        UserDefaults.standard.set(password, forKey: "mqttPassword")
    }

    private func loadSettings() {
        self.host = UserDefaults.standard.string(forKey: "mqttHost")
        self.username = UserDefaults.standard.string(forKey: "mqttUsername")
        self.password = UserDefaults.standard.string(forKey: "mqttPassword")
    }
}



extension MQTTManager: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("topic: \(success)")
        currentAppState.setAppConnectionState(state: .connectedSubscribed)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        TRACE("topic: \(topics)")
        currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
        currentAppState.clearData()
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")

        if ack == .accept {
            currentAppState.setAppConnectionState(state: .connected)
            // Send a message to the "status" topic after connecting
            mqtt.publish("status", withString: "Client connected", qos: .qos1)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string.description), id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string.description), id: \(id)")
        currentAppState.setReceivedMessage(text: message.string.description)
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        TRACE("topic: \(topic)")
        currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
        currentAppState.clearData()
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err.description)")
        currentAppState.setAppConnectionState(state: .disconnected)
    }
}


extension MQTTManager {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 1 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }

        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension Optional {
    // Unwrap optional value for printing log only
    var description: String {
        if let wraped = self {
            return "\(wraped)"
        }
        return ""
    }
}
