//
//  Types.swift
//  SwiftDog
//
//  Created by jacob.aronoff on 5/3/18.
//

public typealias DataPoint = (TimeInterval, Float)

public extension Date {
    public static func currentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}

internal protocol API {
    var base_url: String { get }
    var interval_seconds: TimeInterval { get set }
}

public protocol DataType: Encodable {
    var host: String? { get set }
    var tags: [String] { get set }
}

public protocol Endpoint {
    associatedtype EndpointDataType: DataType
    var endpoint: String { get }
    var tags: [String] { get set }
    mutating func send(series: [EndpointDataType])
}

extension Endpoint {
    internal func create_url(url: String) throws -> URL {
        let api_key = Datadog.dd.keychain[string: "api_key"]
        let app_key = Datadog.dd.keychain[string: "app_key"]
        return URL(string: "https://"+url+self.endpoint + "?api_key=\(api_key!)&application_key=\(app_key!)")!
    }
    internal func _send(url_to_post: URL, json: Data, completion:((Error?) -> Void)?) throws {
        var request = URLRequest(url: url_to_post)
        request.httpMethod = "POST"
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        request.httpBody = json
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                completion?(responseError!)
                return
            }
            // APIs usually respond with the data you just sent in your POST request
            if let data = responseData, let utf8Representation = String(data: data, encoding: .utf8) {
                print("response: ", utf8Representation)
            } else {
                print("no readable data received in response")
            }
        }
        task.resume()
    }
}

enum DatadogAPIError: Error {
    case keyNotSet(String)
    case URLNotCreated(String)
    case unknownError(String)
}