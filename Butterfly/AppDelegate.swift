//
//  AppDelegate.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var schemeOpenUrls: [URL]?
    private var didLaunch = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("icon"))
            button.imagePosition = .imageLeft
            button.action = #selector(show(_:))
        }
        
        constructPopover()
        FirestoreSetup().setup()
        IconImage.shared.clearAllCache()
        SpeechRecognizer.shared.requestAuthorization()
        AudioSystem.shared.setup()
        
        if let urls = schemeOpenUrls {
            urls.forEach { self.openScheme(url: $0) }
        }
        
        didLaunch = true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if didLaunch {
            urls.forEach { self.openScheme(url: $0) }
        } else {
            schemeOpenUrls = urls
        }
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        AuthUser.shared.reloadUser()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        AuthUser.shared.unlistendAuthEvent()
        FirestoreObserver.shared.unlistenWorkspace()
    }
    
    private func openScheme(url: URL) {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path,
              let params = components.queryItems else {
            return
        }
        
        let appScheme = AppScheme()
        switch path {
        case appScheme.openMeetingPath:
            if let workspaceId = params.first(where: { $0.name == appScheme.openMeetingPathWorkspaceIdKey })?.value,
               let meetingId = params.first(where: { $0.name == appScheme.openMeetingPathMeetingIdKey })?.value,
               let vc = popover.contentViewController as? MainViewController {
                vc.openMeeting(workspaceId: workspaceId, meetingId: meetingId)
            }
        default:
            return
        }
    }
    
    private func constructPopover() {
        let mainViewController = MainViewController.create()
        popover.contentViewController = mainViewController
        popover.behavior = .transient
        popover.animates = false
    }

    @objc func show(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}

