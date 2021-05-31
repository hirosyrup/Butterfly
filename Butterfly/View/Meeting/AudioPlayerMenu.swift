//
//  AudioPlayerMenu.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/31.
//

import Cocoa

protocol AudioPlayerMenuDelegate: class {
    func didChangePlaybackRate(menu: AudioPlayerMenu, rate: Float)
}

class AudioPlayerMenu {
    var delegate: AudioPlayerMenuDelegate?
    let initialPlaybackRate = Float(1.0)
    
    func createMenu() -> NSMenu {
        let menu = NSMenu(title: "audio player menu")
        let playbackRateMenuItem = NSMenuItem(title: "playback rate", action: nil, keyEquivalent: "")
        menu.addItem(playbackRateMenuItem)
        let playbackRateMenuItemSubMenu = NSMenu(title: "playbackRateMenuItemSubMenu")
        let rates: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        rates.forEach { (rate) in
            let item = NSMenuItem(title: "\(rate)", action: #selector(clickPlaybackRate(_:)), keyEquivalent: "")
            item.target = self
            playbackRateMenuItemSubMenu.addItem(item)
            if initialPlaybackRate == rate {
                updateSelectedPlaybackRate(menu: playbackRateMenuItemSubMenu, menuItem: item)
            }
        }
        playbackRateMenuItem.submenu = playbackRateMenuItemSubMenu
        
        return menu
    }
    
    private func updateSelectedPlaybackRate(menu: NSMenu, menuItem: NSMenuItem) {
        let selectedMark = " <-"
        menu.items.forEach { $0.title = $0.title.replacingOccurrences(of: selectedMark, with: "") }
        menuItem.title = "\(menuItem.title)\(selectedMark)"
    }
    
    @objc func clickPlaybackRate(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem, let playbackMenu = menuItem.parent?.submenu, let rate = Float(menuItem.title) {
            updateSelectedPlaybackRate(menu: playbackMenu, menuItem: menuItem)
            delegate?.didChangePlaybackRate(menu: self, rate: rate)
        }
    }
}
