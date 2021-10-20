//
//  OtgCameraPositionProtocol.swift
//  SushiWOK
//
//  Created by Andrei Volkau on 03.09.2021.
//  Copyright © 2021 TZNZ. All rights reserved.
//

import GoogleMaps
import YandexMapsMobile

/// General camera position protocol.
protocol OtgCameraPositionProtocol {
    var otgZoom: Float { get }
    var otgTarget: CLLocationCoordinate2D { get }
}

//MARK: - Google maps

extension GMSCameraPosition: OtgCameraPositionProtocol {
    var otgZoom: Float {
        get { return self.zoom }
    }
    var otgTarget: CLLocationCoordinate2D {
        get { return self.target }
     }
}

//MARK: - Yandex maps

extension YMKCameraPosition: OtgCameraPositionProtocol {
    var otgZoom: Float {
        get { return self.zoom }
    }
    var otgTarget: CLLocationCoordinate2D {
        get { return self.target.defaultCoordinate }
    }
}
