/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import PromiseKit

private let appID = "<#Enter Your API Key from http://openweathermap.org/appid#>"

class WeatherHelper {
  struct WeatherInfo: Codable {
    let main: Temperature
    let weather: [Weather]
    var name: String = "Error: invalid jsonDictionary! Verify your appID is correct"
  }

  struct Weather: Codable {
    let icon: String
    let description: String
  }

  struct Temperature: Codable {
    let temp: Double
  }
  
  func getWeather(atLatitude latitude: Double, longitude: Double) -> Promise<WeatherInfo> {
    let url = makeURL(atLatitude: latitude, longitude: longitude)
    
    return firstly {
      URLSession.shared.dataTask(.promise, with: url)
      }.compactMap {
        return try JSONDecoder().decode(WeatherInfo.self, from: $0.data)
    }
  }
  
  private func makeURLstring(atLatitude latitude: Double, longitude: Double) -> String {
    let urlString = "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(appID)"
    return urlString
  }
  
  private func makeURL(atLatitude latitude: Double, longitude: Double) -> URL {
    let urlString = makeURLstring(atLatitude: latitude, longitude: longitude)
    if let url = URL(string: urlString) {
      return url
    }
    else {
      fatalError("Can't make URL from <\(urlString)>. Won't create URL.")
    }
  }
  
  private func saveFile(named: String, data: Data, completion: @escaping (Error?) -> Void) {
    guard let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png") else { return }

    DispatchQueue.global(qos: .background).async {
      do {
        try data.write(to: path)
        print("Saved image to: " + path.absoluteString)
        completion(nil)
      } catch {
        completion(error)
      }
    }
  }
  
  private func getFile(named: String, completion: @escaping (UIImage?, Error?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png"),
        let data = try? Data(contentsOf: path),
        let image = UIImage(data: data) {
        DispatchQueue.main.async { completion(image, nil) }
      } else {
        let error = NSError(domain: "WeatherOrNot",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Image file '\(named)' not found."])
        DispatchQueue.main.async { completion(nil, error) }
      }
    }
  }
  
}

// Retrieve Icon
extension WeatherHelper {
  
  // MARK: - Internal methods
  
  func getIcon(named iconName: String) -> Promise<UIImage> {
    return Promise<UIImage> {
        getFile(named: iconName, completion: $0.resolve)
      }
      .recover { [weak self] _ in
        return self?.getIconFromNetwork(named: iconName) ?? Promise.value(UIImage())
      }
  }
  
  // MARK: - Private methods
  
  private func getIconFromNetwork(named iconName: String) -> Promise<UIImage> {
    let url = makeURL(for: iconName)
    return firstly {
      URLSession.shared.dataTask(.promise, with: url)
      }
      .then(on: DispatchQueue.global(qos: .background)) { response in
        return Promise.value(UIImage(data: response.data) ?? UIImage())
    }
  }
  private func makeURLString(for iconName: String) -> String {
    let urlString = "http://openweathermap.org/img/w/\(iconName).png"
    return urlString
  }
  
  private func makeURL(for iconName: String) -> URL {
    let urlString = makeURLString(for: iconName)
    if let url = URL(string: urlString) {
      return url
    }
    else {
      fatalError("Can't make URL from <\(urlString)>. Won't create URL.")
    }
  }
  
  
}
