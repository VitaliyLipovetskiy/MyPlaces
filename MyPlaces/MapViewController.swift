//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Виталий Липовецкий on 15.06.2020.
//  Copyright © 2020 Виталий Липовецкий. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place!
    let annotationIdentifier = "annotationIdentifier"
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupPlacemark()

    }
    
    @IBAction func closeVC(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func setupPlacemark() {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first //получили метку на карте без информации
            
            let annotation = MKPointAnnotation() // используется для описания точки на карте
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate   // привязываем анотацию к точке на карте
            
            self.mapView.showAnnotations([annotation], animated: true)  // покажем анотацию
            self.mapView.selectAnnotation( annotation, animated: true)  // выделим созданную анотацию
            
        }
        
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // исключаем анотацию пользователя
        guard !(annotation is MKUserLocation) else { return nil }
        
        // не создаем новый, а переназначаем уже созданный ранее
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationIdentifier") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
            
        }

        return annotationView
        
    }
    
}
