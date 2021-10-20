//
//  OtgMarkerProtocol.swift
//  SushiWOK
//
//  Created by Andrei Volkau on 03.09.2021.
//  Copyright © 2021 TZNZ. All rights reserved.
//

import GoogleMaps
import YandexMapsMobile

/// Marker Data
enum MarkerData: String {
    case icon, title, type
    enum MarkerType: String {
        case shop, user, delivery
    }
}

/// General marker protocol.
protocol OtgMarkerProtocol {
    var otgPosition: CLLocationCoordinate2D { get set }
    var markerData: [MarkerData: Any?] { get set }
}

//MARK: - Google maps

extension GMSMarker: OtgMarkerProtocol {
    var otgPosition: CLLocationCoordinate2D {
        get { return self.position }
        set { self.position = newValue }
    }
    
    var markerData: [MarkerData : Any?] {
        get {
            return [.icon: self.icon, .title: self.title]
        }
        set {
            self.icon = newValue[.icon] as? UIImage
            self.title = newValue[.title] as? String
        }
    }
}

//MARK: - Yandex maps

extension YMKPlacemarkMapObject: OtgMarkerProtocol {
    var otgPosition: CLLocationCoordinate2D {
        get { self.geometry.defaultCoordinate }
        set { self.geometry = newValue.yandexPoint }
    }
    
    var markerData: [MarkerData : Any?] {
        get {
            return userData as? [MarkerData: Any?] ?? [:]
        }
        set {
            userData = newValue
        }
    }
}

#warning("add/remove?")
/*
 // Transition animation
 func animateTransition(_ scaleUp: Bool) {
     let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
     let timing = CAMediaTimingFunction(name: .easeOut)
     scaleAnimation.duration = 0.3
     if scaleUp {
         scaleAnimation.fromValue = 1
         scaleAnimation.toValue = 1.4
     } else {
         scaleAnimation.fromValue = 1.4
         scaleAnimation.toValue = 1
     }
     scaleAnimation.fillMode = .both
     scaleAnimation.isRemovedOnCompletion = false
     self.iconView?.layer.add(scaleAnimation, forKey: "transform")
 }
 */
