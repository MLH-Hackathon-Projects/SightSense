//
//  InternetDetector.swift
//  SightSense
//
//  Created by Peter Zhao on 4/6/24.
//

import Network
import Foundation

class ConnectivityChecker {

    static let shared = ConnectivityChecker()

    private var monitor: NWPathMonitor!
    private let queue = DispatchQueue.global(qos: .background)
    private var isConnected: Bool = false

    private init() {
    }

    func startMonitoring() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            //print("internet change detected")
            self.isConnected = (path.status == .satisfied)
        }

        //print("starting network monitor")
        monitor.start(queue: queue)
    }

    func checkConnection() -> Bool {
        return isConnected
    }
    
    func stopMonitoring() {
        //print("stoping network monitor")
        monitor?.cancel()
    }

}
