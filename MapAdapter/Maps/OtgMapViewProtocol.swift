//
//  OtgMapViewProtocol.swift
//  SushiWOK
//
//  Created by Andrei Volkau on 03.09.2021.
//  Copyright © 2021 TZNZ. All rights reserved.
//

import GoogleMaps
import YandexMapsMobile

//MARK: - OtgMapViewProtocol

/// General map view protocol.
protocol OtgMapViewProtocol: UIView {
    typealias Marker = OtgMarkerProtocol
    typealias CameraPosition = OtgCameraPositionProtocol
    
    /// Delegate getter / setter
    var otgDelegate: DelegateAdapterProtocol? { get set }
    /// Represents current camera position
    var cameraPosition: CameraPosition { get }
    /// Represents current camera zoom
    var zoom: Float { get }
    /// Represents currently selected marker.
    var otgSelectedMarker: Marker? { get set }
    
    /// Changes camera position.
    func moveCamera(to target: CLLocationCoordinate2D?, zoom: Float, animated: Bool)
    /// Creates a new marker with style within markerData and adds it to the current map.
    func addMarker(at position: CLLocationCoordinate2D?, markerData: [MarkerData: Any?]) -> Marker?
    /// Removes the given marker from the current map.
    func unpinMarker(marker: Marker)
    /// Clears all markup that has been added to the map, including markers.
    func clearMap()
}


//MARK: - Google maps

class GoogleMapView: GMSMapView, OtgMapViewProtocol {

    //MARK: - Lifecycle
    
    deinit {
        print("\(Self.self) deinited")
    }
    
    //MARK: - Public variables
    
    weak var otgDelegate: DelegateAdapterProtocol? {
        didSet {
            self.delegate = otgDelegate as? GoogleMapDelegate
        }
    }
    
    var cameraPosition: CameraPosition {
        get { return camera }
    }
    
    var zoom: Float {
        get { return cameraPosition.otgZoom }
    }
    
    var otgSelectedMarker: Marker? {
        didSet {
            selectedMarker = otgSelectedMarker as? GMSMarker
        }
    }
    
    //MARK: - Public methods
    
    func moveCamera(to target: CLLocationCoordinate2D?, zoom: Float, animated: Bool) {
        guard let target = target else { return }
        let cameraPosition = GMSCameraPosition(target: target, zoom: zoom)
        if animated {
            self.animate(to: cameraPosition)
        } else {
            self.camera = cameraPosition
        }
    }
    
    func addMarker(at position: CLLocationCoordinate2D?, markerData: [MarkerData : Any?]) -> Marker? {
        let marker = GMSMarker()
        if let position = position {
            marker.position = position
        }
        marker.markerData = markerData
        marker.map = self
        return marker
    }
    
    func unpinMarker(marker: Marker) {
        (marker as? GMSMarker)?.map = nil
    }
    
    func clearMap() {
        self.clear()
    }
}

//MARK: - Yandex maps

class YandexMapView: YMKMapView, OtgMapViewProtocol {
    
    //MARK: - Lifecycle
    
    deinit {
        print("\(Self.self) deinited")
    }
    
    //MARK: - Public variables
    
    weak var otgDelegate: DelegateAdapterProtocol? {
        willSet {
            if let validDelegate = newValue as? YandexMapDelegate {
                self.mapWindow.map.addCameraListener(with: validDelegate)
                self.mapWindow.map.mapObjects.addTapListener(with: validDelegate)
            } else {
                guard let delegate = otgDelegate as? YandexMapDelegate else { return }
                self.mapWindow.map.removeCameraListener(with: delegate)
                self.mapWindow.map.mapObjects.removeTapListener(with: delegate)
            }
        }
    }
    
    var cameraPosition: CameraPosition {
        get { return self.mapWindow.map.cameraPosition }
    }
    
    var zoom: Float {
        get { return cameraPosition.otgZoom }
    }
    
    var otgSelectedMarker: Marker? {
        willSet {
            //previous marker - restore previous image
            if let marker = otgSelectedMarker as? YMKPlacemarkMapObject,
               let icon = (marker.userData as? [MarkerData: Any?])?[.icon] as? UIImage {
                marker.setIconWith(icon)
            }
            //new selected marker - set snippet
            // if nil -> nothing to select
            guard let selectedMarker = newValue as? YMKPlacemarkMapObject,
                  let markerData = selectedMarker.userData as? [MarkerData: Any?],
                  let icon = markerData[.icon] as? UIImage,
                  let title = markerData[.title] as? String else { return }
            
            let iconWithSnippet = createImage(baseImage: icon, from: title)
            selectedMarker.setIconWith(iconWithSnippet)
        }
    }
    
    //MARK: - Public methods
    
    func moveCamera(to target: CLLocationCoordinate2D?, zoom: Float, animated: Bool) {
        guard let target = target else { return }
        let cameraPosition = YMKCameraPosition(target: target.yandexPoint, zoom: zoom, azimuth: 0, tilt: 0)
        if animated {
            self.mapWindow.map.move(with: cameraPosition, animationType: YMKAnimation(type: .smooth, duration: 0.5), cameraCallback: nil)
        } else {
            self.mapWindow.map.move(with: cameraPosition)
        }
    }
    
    func addMarker(at position: CLLocationCoordinate2D?, markerData: [MarkerData : Any?]) -> Marker? {
        guard let position = position else { return nil }
        var marker: YMKPlacemarkMapObject
        if let icon = markerData[.icon] as? UIImage {
            marker = self.mapWindow.map.mapObjects.addPlacemark(with: position.yandexPoint, image: icon)
        } else {
            marker = self.mapWindow.map.mapObjects.addPlacemark(with: position.yandexPoint)
        }
        marker.markerData = markerData
        return marker
    }
    
    func unpinMarker(marker: Marker) {
        guard let yMarker = marker as? YMKPlacemarkMapObject else { return }
        self.mapWindow.map.mapObjects.remove(with: yMarker)
    }
    
    func clearMap() {
        self.mapWindow.map.mapObjects.clear()
    }
    
    //MARK: - Private methods
    
    /// Creates new image with snippet based on main UIImage.
    private func createImage(baseImage: UIImage, from text: String) -> UIImage {
        guard !text.isEmpty else { return baseImage }
        
        // add padding to text label
        let textPadding: CGFloat = 8.0
        let textMargin: CGFloat = 8.0
        // add text attributes
        let resizableFont = UIFont.preferredFont(forTextStyle: .body)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key : Any] = [.font: resizableFont, .paragraphStyle: paragraphStyle]
        
        // put image in image view
        let imageView = UIImageView(image: baseImage)
        imageView.contentMode = .scaleAspectFit
        
        // calculate size that fitting multiline text
        let textSize = text.boundingRect(with: .init(width: UIScreen.main.bounds.width * 0.7, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        
        // calculate whole icon size
        let iconSize: CGSize = .init(width: textSize.width + 2 * textPadding + 2 * textMargin, height: (imageView.bounds.height + textSize.height + textPadding + textMargin) * 2.1)
        
        // move image in the center
        imageView.bounds.origin = .init(x: (iconSize.width - imageView.bounds.width) / 2, y: (iconSize.height - imageView.bounds.height) / 2)
        
        // drawing
        let renderer = UIGraphicsImageRenderer(size: iconSize)
        let img = renderer.image { renderCtx in
            let ctx = renderCtx.cgContext
            // drawing visible text rect
            ctx.saveGState()
            let textRect: CGRect = .init(x: textMargin, y: textMargin, width: iconSize.width - textMargin, height: textSize.height + 2 * textPadding)
            let triangleSide: CGFloat = resizableFont.lineHeight * 0.35
            let cornerRadius: CGFloat = 5.0
            let path = createRoundedSnippetPath(for: textRect, with: cornerRadius, triangleSide: triangleSide)
            ctx.addPath(path.cgPath)
            ctx.setShadow(offset: .zero, blur: 5.0, color: UIColor.gray.cgColor)
            UIColor.white.setFill()
            ctx.fillPath()
            ctx.restoreGState()
            
            // put default marker back
            imageView.layer.render(in: ctx)
            
            // put title
            (text as NSString).draw(in: .init(origin: .init(x: textPadding + textMargin, y: textPadding + textMargin / 2), size: textSize), withAttributes: attributes)
        }
        return img
    }
    
    private func degreeInRadians(_ angle: CGFloat) -> CGFloat {
        return angle * .pi / 180
    }
    
    private func createRoundedSnippetPath(for textRect: CGRect, with cornerRadius: CGFloat, triangleSide: CGFloat) -> UIBezierPath {
        
        let path = UIBezierPath()
        path.move(to: .init(x: textRect.origin.x + cornerRadius, y: textRect.origin.y))
        path.addLine(to: .init(x: textRect.width - 2 * cornerRadius, y: textRect.origin.y))
        path.addArc(withCenter: .init(x: textRect.width - cornerRadius, y: textRect.origin.y + cornerRadius), radius: cornerRadius, startAngle: degreeInRadians(270), endAngle: degreeInRadians(0), clockwise: true)
        
        path.addLine(to: .init(x: textRect.width, y: textRect.height - cornerRadius))
        
        path.addArc(withCenter: .init(x: textRect.width - cornerRadius, y: textRect.height - cornerRadius), radius: cornerRadius, startAngle: degreeInRadians(0), endAngle: degreeInRadians(90), clockwise: true)
        
        let triangleHeight: CGFloat = triangleSide * 1.3
        let middlePointX = textRect.origin.x + (textRect.width - textRect.origin.x) / 2
        path.addLine(to: .init(x: middlePointX + triangleSide, y: textRect.height))
        path.addLine(to: .init(x: middlePointX, y: textRect.height + triangleHeight))
        path.addLine(to: .init(x: middlePointX - triangleSide, y: textRect.height))
        
        path.addLine(to: .init(x: textRect.origin.x + cornerRadius, y: textRect.height))
        path.addArc(withCenter: .init(x: textRect.origin.x + cornerRadius, y: textRect.height - cornerRadius), radius: cornerRadius, startAngle: degreeInRadians(90), endAngle: degreeInRadians(180), clockwise: true)
        path.addLine(to: .init(x: textRect.origin.x, y: textRect.origin.y - cornerRadius))
        path.addArc(withCenter: .init(x: textRect.origin.x + cornerRadius, y: textRect.origin.y + cornerRadius), radius: cornerRadius, startAngle: degreeInRadians(180), endAngle: degreeInRadians(270), clockwise: true)
        path.close()
        return path
    }
    
}
