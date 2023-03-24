//
//  ViewController.swift
//  WeatherApp
//
//  Created by Bishownath Dhakal on 2023-03-13.
//

import UIKit
import MapKit
import CoreLocation

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable{
    let name: String
    let lat: Double
    let lon: Double
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day: Int
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}


class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var isDay: UILabel!
    
    
    @IBOutlet weak var highTemp: UILabel!
    @IBOutlet weak var lowTemp: UILabel!
    @IBOutlet weak var currentLocation: UIButton!
    
    @IBOutlet weak var temperatureConvert_ButtonLabel: UIButton!
//    var temperatureConvert_ButtonLabel = "°F"
    
    var weatherIconCondition: Int = 0
    var weatherCondition: String?
    var isFahrenheit = false
    
    // using CL Location Manager to get the current location
    var locationManager = CLLocationManager()
    
    
    var location: String?
    var lat: Double?
    var lon: Double?
    
    var isChecked = true
    
    var temp_f_global: Float?
    var temp_c_global: Float?
    
    var loadTemp: WeatherResponse?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        searchTF.delegate = self
        
        locationManager.requestAlwaysAuthorization()
        //        locationManager.requestWhenInUseAuthorization()
        
        locationLabel.text = "Mumbai"
        // config for changing the color of the image icon
        let config = UIImage.SymbolConfiguration(paletteColors: [.gray, .white, .yellow])
        
        weatherIcon.preferredSymbolConfiguration = config
        weatherIcon.image = UIImage(systemName: "cloud.fill")
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    //resign keyboard from screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchTF.resignFirstResponder()
    }
    
    // on click search button
    @IBAction func onClickSearchButton(_ sender: UIButton) {
        //
        
        let locationSearch = searchTF.text
        loadWeather(search: locationSearch)
    }
    
    func currentLoc (lat: Double, lon: Double) {
        let londonLocation = CLLocation(latitude: lat, longitude: lon)
        
        let geoCoder = CLGeocoder();
        geoCoder.reverseGeocodeLocation(londonLocation, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            guard placeMark.country != nil else {
                if let city = placeMark.locality {
                    self.loadWeather(search: city);
                }
                return
            }
        });
        
        let radiusInMetres: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: londonLocation.coordinate, latitudinalMeters: radiusInMetres, longitudinalMeters: radiusInMetres)
        
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("My loc = \(locValue.latitude) \(locValue.longitude)")
    }
    
    @IBAction func onTemperatureConvert(_ sender: UIButton) {
        lat = (locationManager.location?.coordinate.latitude)
        lon = (locationManager.location?.coordinate.longitude)
        
        isChecked = !isChecked
        // button

        if isChecked == true{
            print(isChecked)
            temperatureConvert_ButtonLabel.setTitle("F", for: .normal)
            temperatureLabel.text = "\(loadTemp!.current.temp_c)°C"
        }
        else {
            print(isChecked)
            temperatureConvert_ButtonLabel.setTitle("C", for: .normal)
            temperatureLabel.text = "\(loadTemp!.current.temp_f)°F"
        }
    }
    
    // setting current location button in bottom right
    @IBAction func onCurrentLocation(_ sender: UIButton) {
        lat = (locationManager.location?.coordinate.latitude)
        lon = (locationManager.location?.coordinate.longitude)

        print("Latitude \(lat!)")
        print("Longitude \(lon!)")

        loadWeather(search: "\(lat!) \(lon!)")
        
//        isChecked = !isChecked
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.locationLabel.text = textField.text!
        
        loadWeather(search: textField.text)
        textField.text = ""
        return true
    }
    
    private func loadWeather(search: String?) {
        guard let search = search else{
            return
        }
        //        print("Loading the weather")
        
        guard let url = getURL(location: search) else {
            print("NO URL FOUND")
            return  }
        
        // create URL session
        let session = URLSession.shared
        
        // data task create
        let dataTask = session.dataTask(with: url) { data, response, error in
            // network call
            // print("Network called")
            
            guard error == nil else {
                print("Error Occured")
                return
            }
            
            guard let data = data else {
                print("No Data Found")
                return
            }
            
            
            if let weatherResponse = self.parseJSON(data: data){
                
                // since the UI cannot be updated from the background thread but only from main, the dispatch queue comes to an action
                DispatchQueue.main.async { [self] in
                    loadTemp = weatherResponse
                    self.temp_f_global = weatherResponse.current.temp_f
                    self.temp_c_global = weatherResponse.current.temp_c
                    
                    self.locationLabel.text = weatherResponse.location.name
                    
                    if isChecked {
//                        temperatureConvert_ButtonLabel = "°F"
                        print(isChecked)
//                        self.temperatureLabel.text = "\(self.temp_c_global!)°C"
                        self.temperatureLabel.text = "\(self.temp_c_global!)°C"
                        temperatureConvert_ButtonLabel.setTitle("F", for: .normal)
                        
                    }
                    else {
//                        temperatureConvert_ButtonLabel = "°C"
                        print(isChecked)
                        self.temperatureLabel.text = "\(self.temp_f_global!)°F"
                        temperatureConvert_ButtonLabel.setTitle("C", for: .normal)
                        
                    }
                    
                    print(weatherResponse.current.temp_f)
                    print("Float Fah Temp", self.temp_f_global!)
                    
                    self.weatherDescription.text = "\(weatherResponse.current.condition.text)"
                    self.weatherCondition = String("\(weatherResponse.current.condition.code)")
                    let day_night = weatherResponse.current.is_day == 0 ? "Night" : "Day"
                    self.isDay.text = day_night
                    let weatherConditionCode = Int(self.weatherCondition ?? "")
                    
                    // setting up map
                    let location = CLLocation(latitude: weatherResponse.location.lat, longitude: weatherResponse.location.lon)
                    
                    let radiusInMetres: CLLocationDistance = 1000
                    
                    let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radiusInMetres, longitudinalMeters: radiusInMetres)
                    
                    self.map.setRegion(coordinateRegion, animated: true)
                    
                    switch weatherConditionCode {
                        
                        // sunny
                    case 1000:
                        self.weatherIcon.image = UIImage(systemName: "sun.max")
                        
                        // overcast
                    case 1009:
                        self.weatherIcon.image = UIImage(systemName: "cloud.fog.fill")
                        
                        // partly cloudy
                    case 1003:
                        self.weatherIcon.image = UIImage(systemName: "cloud.sun.fill")
                        
                        // cloudy
                    case 1006:
                        self.weatherIcon.image = UIImage(systemName: "cloud")
                        
                        // patchy rain possible
                    case 1063:
                        self.weatherIcon.image = UIImage(systemName: "cloud.rain")
                        
                    case 1189:
                        self.weatherIcon.image = UIImage(systemName: "cloud.rain.fill")
                        
                        //Patchy snow possible
                    case 1066:
                        self.weatherIcon.image = UIImage(systemName: "cloud.snow")
                        
                        // fan blades
                    default:
                        self.weatherIcon.image = UIImage(systemName: "fanblades")
                    }
                }
                
                print(weatherResponse.location.name)
            }
            else{
                DispatchQueue.main.async {
                    print("Couldn't find a weather")
                    let alertController = UIAlertController(title: "Error", message: "Please enter a city or location", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .destructive)
                    alertController.addAction(alertAction)
                    self.show(alertController, sender: nil)
                }
            }
        }
        // Dispatch main async end
        
        // start datatask
        dataTask.resume()
    }
    private func parseJSON(data: Data) -> WeatherResponse? {
        // decode the data
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        }
        catch {
            print(error)
        }
        return weather
    }
    
    private func getURL(location: String) -> URL? {
        // get URL
        let baseURL = "https://api.weatherapi.com/v1/"
        let dataFormat="current.json"
        let apiKey = "faaa1f147c434780ac613149231403"
        
        guard let endpoint = "\(baseURL)\(dataFormat)?key=\(apiKey)&q=\(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return nil
        }
        //        print(endpoint)
        return URL(string: endpoint)
    }
}

