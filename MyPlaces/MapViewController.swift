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

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    
    // менеджер, который отвечает за настройку и управление службами геолокации
    // на устройсве должны быть включены соответствующие слыжбы геолокации
    let locationManager = CLLocationManager()
    
    let regionInMeters = 1_000.00
    
    var incomSegueIdentifier = ""
    
    var placeCoordinate: CLLocationCoordinate2D?
    
    // массив маршрутов, что-бы при перепроложении можно было отменить старый маршрут и проложить новый
    var directionsArray: [MKDirections] = []
    
    // предыдщее положение пользователя
    var previousLocation: CLLocation? {
        didSet {
            staartTrackingUserLocation()
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {
        
        showUserLocation()
        
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
        
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    @IBAction func closeVC(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func setupMapView() {
        
        // Скрываем кнопку, показывать ее будем только при переходе по "showPlace"
        goButton.isHidden = true
        
        if incomSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    // метод удаляет все маршруты с карты и его надо вызывать перед тем как создать новый маршрут
    private func resetMapView(withNew directions: MKDirections) {
        
        //перед постройкой маршрута надо удалить с карты наложения текущего маршрута
        mapView.removeOverlays(mapView.overlays)
        
        directionsArray.append(directions)
        
        // отменим маршруты у каждого элемента массива маршрутов
        // с помощью замыкания проходимся по элементам и выполняем метод cancel()
        let _ = directionsArray.map { $0.cancel() }
        
        // удаляем все элементы из массива
        directionsArray.removeAll()

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
            // для построения маршрута сохраним кординаты в свойстве
            self.placeCoordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)  // покажем анотацию
            self.mapView.selectAnnotation(annotation, animated: true)  // выделим созданную анотацию
            
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
            if incomSegueIdentifier == "getAddress" { showUserLocation() }
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
    
    private func staartTrackingUserLocation() {
        
        guard let previousLocation = previousLocation else { return }
        let center = getCenterLocation(for: mapView)
        // определим растояние до центра текущей области
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
        
        
    }
    
    // прокладка маршрута
    private func getDirections() {
        
        //определим оординаты пользователя
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current locatio is not found")
            return
        }
        
        //включим режим постоянного отслеживания пользователя
        locationManager.startUpdatingLocation()
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        //выполним запрос на прокладку маршрута
        guard let request = createDirectionsRequest(from:  location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)
        
        // перед созданием новых маршрутов надо удалить старые
        resetMapView(withNew: directions)
        
        // запустим расчет маршрута
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Directions is not available")
                return
            }
            // массив response содержит маршруты
            // если не запрашивать альтернативные машруты, то получим не более 1 объекта маршрута
            for route in response.routes {
                //каждый объект маршру содержит геометрию маршрута
                self.mapView.addOverlay(route.polyline)
                // сфокусируем карту так, что-бы весь маршрут видели целиком
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                // определим расстояние и время в пути
                // расстояние в метрах
                let distance = String(format: "%.1f", route.distance / 1000)
                // время в секундах
                let timeInterval = route.expectedTravelTime
                
                print("расстояние до места \(distance) км, время в пути \(timeInterval) сек")
                // вывести на экран в лейбел, скрыть при загрузке и отображать после построения маршрута передав в него эти значения
            }
            
            
        }
        
        
    }
    
    // настройка построения маршрута
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }
        //определим положение точки для начала маршрута А
        let startingLocation = MKPlacemark(coordinate: coordinate)
        // определим положение точки назначения Б
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        // теперь можем построить маршрут от точки А до точки Б
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark:   startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        //  зададим возможность построения альтернативных маршрутов
        request.requestsAlternateRoutes = true
        
        return request
        
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
        
        if incomSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUserLocation()
            }
        }
        
        // для освобождения ресурсов связанных с геокодированием рекомендуется делать отмену отложенного запроса
        geocoder.cancelGeocode()
        
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
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }

    //для подсветки альтернативных путе другим цветом
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // создадим линию по наложению маршрута
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
        
    }
    
}

extension MapViewController: CLLocationManagerDelegate {   // для отслеживания в реальном времени статуса разрешения для служб геолокации
    
    // вызывается при каждом изминении статуса приложения для использования служб геолокации
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
}
