//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Виталий Липовецкий on 15.06.2020.
//  Copyright © 2020 Виталий Липовецкий. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    
    // менеджер, который отвечает за настройку и управление службами геолокации
    // на устройсве должны быть включены соответствующие слыжбы геолокации
    let locationManager = CLLocationManager()
    
    let regionInMeters = 10_000.00
    
    var incomSegueIdentifier = ""
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adressLabel.text = ""
        mapView.delegate = self
        setupMapView()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {
        
        showUserLocation()
        
    }
    
    @IBAction func doneButtonPressed() {
    }
    
    @IBAction func closeVC(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func setupMapView() {
        
        if incomSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true
            adressLabel.isHidden = true
            doneButton.isHidden = true
        }
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
    
    private func checkLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // надо вызвать алерт контроллер с рекомендацией и инструкцией по включению служб геолокации
            // Show alert controller
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {     // откладываем вызов алерта на 1 сек
                self.showAlert(
                    title: "Location Services are Disabled",
                    message: "To enable it go: Settings -> Privacy -> Location Services and turn On")
            }
        }
    
    }
    
    private func setupLocationManager() {
        
        locationManager.delegate = self
        
        // настроим точность определения местоположения пользователя
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    }
    
    private func checkLocationAuthorization() {
        
        // нужно потоянно мониторить статус авторизации приложения для служб геолокации
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:   // разрешено определять геолокацию в момент его использования
            mapView.showsUserLocation = true
            if incomSegueIdentifier == "getAdress" { showUserLocation() }
            break
        case .denied:                // отказано использовать службы геолокации
            // Show alert controller
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Your Location is not Availeble",
                    message: "To give permission Go to: Settings -> MyPlaces -> Location")
            }
            break
        case .notDetermined:         // статус не определен, возвращается, если пользователь еще не сделал выбор
            locationManager.requestWhenInUseAuthorization() // запрашиваем разрешение и объясняем зачем
//            break
        case .restricted:            // приложение не авторизовано для служб геолакации
            // нужно вызвать алерт контроллер
            break
        case .authorizedAlways:       // разешено постоянно службы геолокации
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    private func showUserLocation() {
        
        // пытаемся рпределить координаты пользовтеля
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    // метод для определения координат в центре экрана
    private func getCenterLocation(for mapView: MKMapView ) -> CLLocation {
        // надо знать широту и долготу
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
        
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
    
    // выполняется каждый раз при смене отображаемого на карте региона
    // в нем будем отображать адрес, который находится в центре региона
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        // вызываем метод отвечающий за преобразование географических координат и названий
        let geocoder = CLGeocoder()
        // преобразуем координаты в название
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                    self.adressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.adressLabel.text = "\(streetName!)"
                } else {
                    self.adressLabel.text = ""
                }
            }
        }
    }

}

extension MapViewController: CLLocationManagerDelegate {   // для отслеживания в реальном времени статуса разрешения для служб геолокации
    
    // вызывается при каждом изминении статуса приложения для использования служб геолокации
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
}
