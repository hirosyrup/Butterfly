//
//  MeetingDateInputViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/20.
//

import Cocoa

protocol MeetingDateInputViewControllerDelegate: class {
    func willClose(vc: MeetingDateInputViewController)
}

class MeetingDateInputViewController: NSViewController {
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var yearInputContainer: NSStackView!
    @IBOutlet weak var yearInputLabel: NSTextField!
    @IBOutlet weak var yearInputStepper: NSStepper!
    @IBOutlet weak var monthAndYearPicker: NSDatePicker!
    @IBOutlet weak var dateRangeInputContainer: NSStackView!
    @IBOutlet weak var dateRangeStartPicker: NSDatePicker!
    @IBOutlet weak var dateRangeEndPicker: NSDatePicker!
    
    weak var delegate: MeetingDateInputViewControllerDelegate?
    private var didChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        reset()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if didChange {
            save()
        }
        delegate?.willClose(vc: self)
    }
    
    private func updateViews() {
        yearInputContainer.isHidden = true
        monthAndYearPicker.isHidden = true
        dateRangeInputContainer.isHidden = true
        switch segmentedControl.selectedSegment {
        case 1:
            yearInputContainer.isHidden = false
        case 2:
            monthAndYearPicker.isHidden = false
        case 3:
            dateRangeInputContainer.isHidden = false
        default:
            break
        }
    }
    
    private func save() {
        var startDate = Date()
        var endDate = Date()
        let calendar = Calendar.current
        switch segmentedControl.selectedSegment {
        case 1:
            let year = yearInputStepper.integerValue
            startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1, hour: 0, minute: 0, second: 0))!
            endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
        case 2:
            let date = monthAndYearPicker.dateValue
            let comps = calendar.dateComponents([.year, .month], from: date)
            startDate = calendar.date(from: comps)!
            let add = DateComponents(month: 1, second: -1)
            endDate = calendar.date(byAdding: add, to: startDate)!
        case 3:
            let rangeStart = dateRangeStartPicker.dateValue
            let rangeEnd = dateRangeEndPicker.dateValue
            let startComps = calendar.dateComponents([.year, .month, .day], from: rangeStart)
            startDate = calendar.date(from: startComps)!
            let endComps = calendar.dateComponents([.year, .month, .day], from: rangeEnd)
            let add = DateComponents(day: 1, second: -1)
            endDate = calendar.date(byAdding: add, to: calendar.date(from: endComps)!)!
        default:
            break
        }
        let userDefault = SearchOptionUserDefault.shared
        userDefault.saveDateSegment(segment: segmentedControl.selectedSegment)
        userDefault.saveDateRangeStart(date: startDate)
        userDefault.saveDateRangeEnd(date: endDate)
    }
    
    private func reset() {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        yearInputStepper.minValue = Double(year - 100)
        yearInputStepper.maxValue = Double(year + 100)
        yearInputStepper.integerValue = year
        yearInputLabel.stringValue = yearInputStepper.stringValue
        monthAndYearPicker.dateValue = date
        dateRangeStartPicker.dateValue = date
        dateRangeEndPicker.dateValue = date
    }
    
    @IBAction func didChangeSegmentControl(_ sender: Any) {
        didChange = true
        updateViews()
        reset()
    }
    
    @IBAction func didChangeYearStepper(_ sender: Any) {
        yearInputLabel.stringValue = yearInputStepper.stringValue
    }
}
