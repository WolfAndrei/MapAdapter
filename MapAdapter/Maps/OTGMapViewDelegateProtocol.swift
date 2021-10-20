//
//  OTGMapViewDelegateProtocol.swift
//  SushiWOK
//
//  Created by Andrei Volkau on 03.09.2021.
//  Copyright © 2021 TZNZ. All rights reserved.
//

import GoogleMaps
import YandexMapsMobile

//MARK: - DelegateAdapterProtocol

/// Adapter protocol
protocol DelegateAdapterProtocol: NSObject {
    init(delegate: OTGMapViewDelegateProtocol)
}

//MARK: - OTGMapViewDelegateProtocol

/// MapDelegateProtcol for VC.
protocol OTGMapViewDelegateProtocol: AnyObject {
    typealias MapView = OtgMapViewProtocol
    typealias Marker = OtgMarkerProtocol
    typealias CameraPosition = OtgCameraPositionProtocol
    
    var otgMapView: MapView! { get set }
    
    /// Camera position is about to change.
    func mapView(_ mapView: MapView, willMove gesture: Bool)
    /// Camera position change is in progress.
    func mapView(_ mapView: MapView, didChange position: CameraPosition)
    /// Camera position was changed.
    func mapView(_ mapView: MapView, idleAt position: CameraPosition)
    /// Marker tap event.
    func mapView(_ mapView: MapView, didTap marker: Marker) -> Bool
}


//MARK: - Google maps

class GoogleMapDelegate: NSObject, GMSMapViewDelegate, DelegateAdapterProtocol {
    
    //MARK: - Public variables
    
    weak var delegate: OTGMapViewDelegateProtocol?
    
    //MARK: - Lifecycle
    
    required init(delegate: OTGMapViewDelegateProtocol) {
        self.delegate = delegate
        super.init()
    }
    
    deinit {
        print("\(Self.self) deinited")
    }
    
    //MARK: - Public methods
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        guard let mv = delegate?.otgMapView else { return }
        delegate?.mapView(mv, willMove: gesture)
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        guard let mv = delegate?.otgMapView else { return }
        delegate?.mapView(mv, didChange: position)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        guard let mv = delegate?.otgMapView else { return }
        delegate?.mapView(mv, idleAt: position)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let mv = delegate?.otgMapView else { return false }
        return delegate?.mapView(mv, didTap: marker) ?? false
    }
}


//MARK: - Yandex maps

class YandexMapDelegate: NSObject, YMKMapObjectTapListener, YMKMapCameraListener, DelegateAdapterProtocol {
    
    //MARK: - Public variables
    
    weak var delegate: OTGMapViewDelegateProtocol?
    
    //MARK: - Lifecycle
    
    required init(delegate: OTGMapViewDelegateProtocol) {
        self.delegate = delegate
        super.init()
    }
    
    deinit {
        print("\(Self.self) deinited")
    }
    
    //MARK: - Public methods
    
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        guard let mv = delegate?.otgMapView else { return false }
        guard let marker = mapObject as? YMKPlacemarkMapObject else { return false }
        return delegate?.mapView(mv, didTap: marker) ?? false
    }
    
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {
        guard let mv = delegate?.otgMapView else { return }
        
        var gesture = false
        switch cameraUpdateReason {
        case .gestures:
            gesture = true
        default:
            break
        }
        /// Camera position is about to change.
        delegate?.mapView(mv, willMove: gesture)
        /// Camera position change is in progress.
        delegate?.mapView(mv, didChange: cameraPosition)
        
        if finished {
            /// Camera position was changed.
            delegate?.mapView(mv, idleAt: cameraPosition)
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }
}
extension CLLocationCoordinate2D {
    var yandexPoint: YMKPoint {
        return YMKPoint(latitude: self.latitude, longitude: self.longitude)
    }
}

extension YMKPoint {
    var defaultCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
