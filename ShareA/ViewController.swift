
//
//  ViewController.swift
//  EventKitUITest
//
//  Created by Home on 3/5/17.
//  Copyright © 2017 Home. All rights reserved.
//

///////
/*
 Things to look at:
    if granted permission on 1st run, access to calendar data not available till
    you rerun project
 
    'Reading from private effective user settings.' 
        when you edit calendars(try to add new calendar) in chooser
 
    constraint problems when you tap cell -> event details vc
 
    'EKAlarmsViewModel was initialized with a nil calendarItem.' 
        when you pop back from event details vc
 
    setting alarms in event details vc doesn't work
 
    'Need the following entitlement in order to determine if MobileCal has location authorization required to do location predictions: com.apple.locationd.effective_bundle' 
            when you try to edit event details vc
 
    anything else you may see that may assist project
*/
///////

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {

    var data = EventData()
    
    @IBOutlet weak var tableview: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        tableview.reloadData()
    }
}

//MARK: - TableView
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.multiCalendarArray.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data.multiCalendarArray[section].calendarTitle
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.multiCalendarArray[section].calendarItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let cellData = data.multiCalendarArray[indexPath.section].calendarItems[indexPath.row]
        cell?.textLabel?.text = cellData.title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = data.multiCalendarArray[indexPath.section].calendarItems[indexPath.row]
        let controller = EKEventViewController()
        controller.event = event
        controller.delegate = self
        controller.allowsEditing = true
        self.navigationController?.pushViewController(controller, animated: true)
        tableview.deselectRow(at: indexPath, animated: false)
    }
}

//MARK: - Actions
extension ViewController {
    @IBAction func calendarBtn(_ sender: UIButton) {
        let calendarChooser = EKCalendarChooser(selectionStyle: EKCalendarChooserSelectionStyle.multiple, displayStyle: EKCalendarChooserDisplayStyle.allCalendars , eventStore: data.eventStore)
        
        calendarChooser.navigationItem.leftBarButtonItem = calendarChooser.editButtonItem
        calendarChooser.delegate = self
        calendarChooser.showsDoneButton = true
        if !data.selectedCalendars.isEmpty {
            calendarChooser.selectedCalendars = data.selectedCalendars
        }
        self.navigationController?.pushViewController(calendarChooser, animated: true)
    }
    
    @IBAction func addBtn(_ sender: UIButton) {
        let controller = EKEventEditViewController()
        controller.eventStore = data.eventStore
        controller.editViewDelegate = self
        self.present(controller, animated: true, completion: nil)
    }
}

//MARK: - EventKit Delegates
extension ViewController: EKCalendarChooserDelegate, EKEventEditViewDelegate, EKEventViewDelegate {
    // CalendarChooser Delegate
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        calendarChooser.navigationController!.popViewController(animated: true)
    }
    
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        data.selectedCalendars = calendarChooser.selectedCalendars
        data.reloadCalendars()
        calendarChooser.navigationController!.popViewController(animated: true)
        tableview.reloadData()
    }
    
    //EventViewController Delegate
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        switch action {
        case EKEventViewAction.done:
            self.data.reloadCalendars()
        case EKEventViewAction.deleted:
            self.data.reloadCalendars()
            controller.navigationController!.popViewController(animated: true)
        case .responded:
            break
        }
        tableview.reloadData()
    }
    
    //EventEditViewController Delegate
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .deleted, .saved:
            self.data.reloadCalendars()
            tableview.reloadData()
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

