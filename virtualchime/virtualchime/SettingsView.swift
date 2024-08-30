//
//  SettingsView.swift
//  virtualchime
//
//  Created by Timo Weiß on 30.08.24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var brokerAddress: String
    @State private var username: String
    @State private var password: String
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordShowing: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var mqttManager = MQTTManager.shared()

    init() {
        // Initialize the state properties with stored values from MQTTManager
        let mqttManager = MQTTManager.shared()
        _brokerAddress = State(initialValue: mqttManager.currentHost() ?? "")
        _username = State(initialValue: mqttManager.mqttUsername)
        _password = State(initialValue: mqttManager.mqttPassword)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MQTT Broker Settings")) {
                    TextField("Broker Address", text: $brokerAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .border(showError && errorMessage.contains("Broker") ? Color.red : Color.clear)
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .border(showError && errorMessage.contains("Username") ? Color.red : Color.clear)
                    HStack {
                        Group {
                            if isPasswordShowing {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .border(showError && errorMessage.contains("Password") ? Color.red : Color.clear)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        
                        Button {
                            isPasswordShowing.toggle()
                        } label: {
                            Image(systemName: isPasswordShowing ? "eye.slash" : "eye")
                        }
                        .foregroundColor(.black)
                    }
                }

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                HStack {
                    Spacer()
                    Button("Save") {
                        saveSettings()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func saveSettings() {
        mqttManager.initializeMQTT(host: brokerAddress, identifier: "iOS_Client", username: username, password: password)
        mqttManager.connect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if mqttManager.isConnected() {
                presentationMode.wrappedValue.dismiss()
            } else {
                showError = true
                errorMessage = "Failed to connect to the broker. Check the credentials."
            }
        }
    }
}


#Preview {
    SettingsView()
}

