//
//  ViewController.swift
//  WeatherApp
//
//  Created by Bishownath Dhakal on 2023-03-13.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var weatherDescription: UILabel!
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var weatherIcon: UIImageView!
    
    
    @IBOutlet weak var isDay: UILabel!
    
    @IBOutlet weak var fahrenheitButton: UIButton!
    
    var weatherIconCondition: Int = 0
    var weatherCondition: String?
    
    var isFahrenheit = false
    
    // using CL Location Manager to get the current location
    var locationManager = CLLocationManager()
    
    var location: String?
    var lat: Double?
    var lon: Double?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        Do any additional setup after loading the view.
        temperatureLabel.text = "-5°C"
        weatherDescription.text = "Partly Cloudy"
        
        searchTF.delegate = self
        
        // config for changing the color of the image icon
        let config = UIImage.SymbolConfiguration(paletteColors: [.gray, .white, .yellow])
        
        weatherIcon.preferredSymbolConfiguration = config
        weatherIcon.image = UIImage(systemName: "cloud.fill")
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    
    // TODO
    @IBAction func onChangeToFahrenheit(_ sender: UIButton) {
//
//        let location: Location = WeatherResponse(from: <#Decoder#>)
//        isFahrenheit = !isFahrenheit
//        if self.isFahrenheit {
//            self.temperatureLabel.text = "\(location.current.temp_f)°F"
//            self.fahrenheitButton.titleLabel?.text = "°C"
//        }
//        else {
//            self.temperatureLabel.text = "\(location.current.temp_c)°C"
//            self.fahrenheitButton.titleLabel?.text = "°F"
//        }
//
//
        print("Change to Fahrenheit")

    }
    
    // setting current location button in bottom right
    @IBAction func onCurrentLocation(_ sender: UIButton) {
        
        // setting up map
        let location = CLLocation(latitude: 42.98339, longitude: -81.23304)
        
        let radiusInMetres: CLLocationDistance = 1000
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radiusInMetres, longitudinalMeters: radiusInMetres)
        
        map.setRegion(coordinateRegion, animated: true)
        
        print("Current Location bottom button")
        
        locationManager(locationManager, didUpdateLocations: [location])
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        self.locationLabel.text = textField.text
        
        loadWeather(search: textField.text)
        textField.text = ""
        return true
    }
    
    
    private func loadWeather(search: String?) {
        guard let search = search else{
            return
        }
        print("Loading the weather")
        
        
        guard let url = getURL(location: search) else {
            print("NO URL FOUND")
            return  }
        
        // create URL session
        let session = URLSession.shared
        
        // data task create
        let dataTask = session.dataTask(with: url) { data, response, error in
            // network call
            print("Network called")
            
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
                DispatchQueue.main.async {
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureLabel.text = "\(weatherResponse.current.temp_c)°C"
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
                    
                    
                    print("Weather ICON CONDITION", self.weatherCondition ?? "")
                    
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
        print(endpoint)
        return URL(string: endpoint)
    }
    
}

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

