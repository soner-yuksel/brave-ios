// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveShared

extension BraveSyncAPI {
    
    public static let seedByteLength = 32
    private static var serviceObservers = NSHashTable<BraveSyncServiceListener>.weakObjects()
    private static var deviceObservers = NSHashTable<BraveSyncDeviceListener>.weakObjects()
    
    var isInSyncGroup: Bool {
        return Preferences.Chromium.syncEnabled.value
    }
    
    @discardableResult
    func joinSyncGroup(codeWords: String) -> Bool {
        if self.setSyncCode(codeWords) {
            Preferences.Chromium.syncEnabled.value = true
            return true
        }
        return false
    }
    
    //See: BraveSyncDevice.remove() for more info.
    /*func removeDeviceFromSyncGroup(deviceGuid: String) {
        BraveSyncAPI.shared.removeDevice(deviceGuid)
    }*/
    
    func leaveSyncGroup() {
        // Remove all observers before leaving the sync chain
        BraveSyncAPI.removeAllObservers()
        
        BraveSyncAPI.shared.resetSync()
        Preferences.Chromium.syncEnabled.value = false
    }
    
    static func addServiceStateObserver(_ observer: @escaping () -> Void) -> AnyObject {
        let result = BraveSyncServiceListener(observer, onRemoved: { observer in
            serviceObservers.remove(observer)
        })
        serviceObservers.add(result)
        return result
    }
    
    static func addDeviceStateObserver(_ observer: @escaping () -> Void) -> AnyObject {
        let result = BraveSyncDeviceListener(observer, onRemoved: { observer in
            deviceObservers.remove(observer)
        })
        deviceObservers.add(result)
        return result
    }
    
    static func removeAllObservers() {
        serviceObservers.objectEnumerator().forEach({
            ($0 as? BraveSyncServiceListener)?.remove()
        })
        
        deviceObservers.objectEnumerator().forEach({
            ($0 as? BraveSyncDeviceListener)?.remove()
        })
        
        serviceObservers.removeAllObjects()
        deviceObservers.removeAllObjects()
    }
}

extension BraveSyncAPI {
    private class BraveSyncServiceListener: NSObject {
        private var observer: BraveSyncServiceObserver?
        private var onRemoved: (BraveSyncServiceListener) -> Void

        fileprivate init(_ onSyncServiceStateChanged: @escaping () -> Void,
                         onRemoved: @escaping (BraveSyncServiceListener) -> Void) {
            self.onRemoved = onRemoved
            self.observer = BraveSyncServiceObserver(callback: onSyncServiceStateChanged)
            super.init()
        }
        
        deinit {
            self.onRemoved(self)
        }
        
        fileprivate func remove() {
            observer = nil
        }
    }
    
    private class BraveSyncDeviceListener: NSObject {
        private var observer: BraveSyncDeviceObserver?
        private var onRemoved: (BraveSyncDeviceListener) -> Void
        
        fileprivate init(_ onDeviceInfoChanged: @escaping () -> Void,
                         onRemoved: @escaping (BraveSyncDeviceListener) -> Void) {
            self.onRemoved = onRemoved
            self.observer = BraveSyncDeviceObserver(callback: onDeviceInfoChanged)
            super.init()
        }
        
        deinit {
            self.onRemoved(self)
        }
        
        fileprivate func remove() {
            observer = nil
        }
    }
}
