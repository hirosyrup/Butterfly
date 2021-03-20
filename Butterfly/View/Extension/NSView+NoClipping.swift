//
//  NSView+NoClipping.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/20.
//

import Cocoa

extension NSView {
    func offClipping() {
        wantsLayer = true
        layer?.masksToBounds = false
    }
}
