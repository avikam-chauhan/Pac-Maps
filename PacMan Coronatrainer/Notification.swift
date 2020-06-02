//
//  Notification.swift
//  PacMan Coronatrainer
//
//  Created by Mihir Chauhan on 6/2/20.
//  Copyright © 2020 Avikam Chauhan. All rights reserved.
//

import Foundation
import UserNotifications
class Notification {
    public static func firebaseMessageToLocalNotification(message text: String) {
        switch text {
        case "Contact with positive player":
            makeLocalNotificationMessage(title: "Critical Alert", message: "You have been within close contact with someone who reported as positive for COVID-19")
            break
            
        default:
            print("The inputted message is not valid: \(text)")
            return
        }
    }
    
    public static func makeLocalNotificationMessage(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
//        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
//            //tell user to activate later through settings if granted != true
//        }
        
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = message
        
        let date = Date().addingTimeInterval(0)
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        
        let uuidString = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            //TODO: Handle error later
        }
                
    }
}
