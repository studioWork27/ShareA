//
//  EventData.swift
//  EventKitUITest
//
//  Created by Home on 3/5/17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import UIKit
import EventKit

struct EventData {
    let formatter = DateFormatter()
    var eventStore: EKEventStore!
    var events: [EKEvent]!
    var calendars: [EKCalendar]?
    var selectedCalendars = Set<EKCalendar>()
    var multiCalendarArray = [CalendarData]()
    
    init() {
        self.eventStore = EKEventStore()
        self.events = [EKEvent]()
        checkCalendarAuthorizationStatus()
    }
}

extension EventData {
    func dateString(date: Date) -> String {
        return formatter.shortDateStr(date: date)
    }
    
    mutating func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            if requestAccessToCalendar() {
                self.loadSelectedCalendars()
                self.loadCalendarsForData()
            }
        case EKAuthorizationStatus.authorized:
            self.loadSelectedCalendars()
            self.loadCalendarsForData()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            break
            // Will add alert for this
        }
    }
    
    mutating func requestAccessToCalendar() -> Bool {
        var permission = false
        eventStore.requestAccess(to: .event, completion:  { (granted, error) in
            permission = granted
        })
        return permission
    }
    
    mutating func loadSelectedCalendars() {
        self.calendars = eventStore.calendars(for: .event)
        _  = calendars!.map {selectedCalendars.insert($0)}
    }
    
    mutating func reloadCalendars() {
        self.loadCalendarsForData()
    }

    mutating func loadCalendarsForData() {
        multiCalendarArray = []
  
        for calendar in selectedCalendars {
            
            let startDate = formatter.loadDateString(dateString: "2016-01-01")
            let endDate = formatter.loadDateString(dateString: "2017-12-31")
            
            if let startDate = startDate, let endDate = endDate {
                
                let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
                
                let calEvents = eventStore.events(matching: eventsPredicate).sorted(){
                    (e1: EKEvent, e2: EKEvent) -> Bool in
                    return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
                }
                multiCalendarArray.append(CalendarData(calendarItems: calEvents, calendarTitle: calendar.title))
            }
        }
        multiCalendarArray = multiCalendarArray.sorted{$0.calendarTitle < $1.calendarTitle}
    }
}

struct CalendarData{
    var calendarItems = [EKEvent]()
    var calendarTitle = ""
}
