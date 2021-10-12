//
//  LocationManager.swift
//  DemoLocationUpdateRealTime
//
//  Created by iOS Dev on 12/10/2564 BE.
//

import Foundation
import UIKit
import CoreLocation

class LocationManager :NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance = LocationManager()
    let locationManager = CLLocationManager()
    var timer: Timer?
    var coordinate: CLLocationCoordinate2D!
    var currentBgTaskId : UIBackgroundTaskIdentifier?
    
    private override init(){
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.activityType = .other;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.allowsBackgroundLocationUpdates = true

        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc func applicationEnterBackground(){
        start()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func start() {
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .authorizedAlways:
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
//            locationManager.requestAlwaysAuthorization()
            break
        case .denied:
            showAlertSettingLocation()
            break
        case .authorizedWhenInUse:
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            showAlertSettingLocation()
            break
        default:
            print("Unhandled authorization status")
            showAlertSettingLocation()
            break
        }
    }
    @objc func restart() {
        timer?.invalidate()
        timer = nil
        start()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.restricted: break
            //log("Restricted Access to location")
        case CLAuthorizationStatus.denied: break
            //log("User denied access to location")
        case CLAuthorizationStatus.notDetermined: break
            //log("Status not determined")
        default:
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        locationManager.stopUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(timer==nil){
            beginNewBackgroundTask()
            locationManager.stopUpdatingLocation()
            
            if locations.last != nil {
                coordinate = locations.last?.coordinate
                let latlng = "Lat : \(coordinate.latitude) \nLng : \(coordinate.longitude)"
                
                let timeNow = Date()
                let dateFormatter2 = DateFormatter()
                dateFormatter2.timeZone = .current
                dateFormatter2.dateFormat = "HHmmss"
                let time = dateFormatter2.string(from: timeNow)
                print(latlng)
                print("time\(time)")
            }
        }
    }
    

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        beginNewBackgroundTask()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    

    

    func beginNewBackgroundTask(){
        var previousTaskId = currentBgTaskId;
        currentBgTaskId = UIApplication.shared.beginBackgroundTask {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        if let taskId = previousTaskId{
            UIApplication.shared.endBackgroundTask(taskId)
            previousTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(0.1), target: self, selector: #selector(self.restart),userInfo: nil, repeats: false)
    }
    
    func showAlertSettingLocation() {
        let alert = UIAlertController(title: "กรุณาเปิดตำแหน่งที่ตั้งของคุณ!",
                                      message: "เพื่ออนุญาตการเข้าถึงตำแหน่งที่ตั้งของคุณ เพื่อแสดงตำแหน่งปัจจุบันและระบุตำแหน่งตัวคุณ",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "ไปที่การตั้งค่า",
                                      style: UIAlertAction.Style.default,
                                      handler: { (alert: UIAlertAction!) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: nil)
        }))
//        self.present(alert, animated: true, completion: nil)
    }
}

