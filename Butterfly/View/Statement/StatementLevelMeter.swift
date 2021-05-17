//
//  StatementLevelMeter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/08.
//

import Cocoa

class StatementLevelMeter: NSView {
    @IBOutlet weak var levelMeter: NSLevelIndicator!
    
    private var enabled = false
    private let minRms = -70.0
    private let maxRms = 6.0
    private let range = 76.0
    
    static func createFromNib(owner: Any?) -> StatementLevelMeter? {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "StatementLevelMeter", bundle: nil)?.instantiate(withOwner: owner, topLevelObjects: &objects)
        return objects?.first{ $0 is StatementLevelMeter } as? StatementLevelMeter
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        levelMeter.criticalValue = (-minRms / range) * levelMeter.maxValue
    }
    
    func updateThreshold(threshold: Double) {
        guard enabled else { return }
        var _threshold = max(minRms, threshold)
        _threshold = min(maxRms, _threshold)
        let rate = (_threshold - minRms) / range
        let x = CGFloat(Double(bounds.width) * rate)
        levelMeter.warningValue = rate * levelMeter.maxValue
    }
    
    func setRms(rms: Double) {
        var _rms = max(minRms, rms)
        _rms = min(maxRms, _rms)
        let rate = (_rms - minRms) / range
        levelMeter.doubleValue = rate * levelMeter.maxValue
    }
    
    func setEnable(enabled: Bool) {
        self.enabled = enabled
        levelMeter.doubleValue = 0.0
    }
}
