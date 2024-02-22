//
//  AuthManager.swift
//  Spotify
//
//  Created by Mohamed on 19/12/2023.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()
    
    struct Constants {
        //Me
        static let clientID = "5b579e4e88a6432b8c607668bda74dd7"
        static let clientSecret = "b39ef1a4c8824bb9ac8b5ecea8584b8c"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.iosacademy.io"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-private%20playlist-modify-private%20user-library-modify%20user-library-read%20user-read-email"
        //ios academy
        //        static let clientID = "87510d91dc934b108f95939901ce613b"
        //        static let clientSecret = "1f89ee6154e44913927b503299cbc37d"
    }
    
    private init() {}
    
    public var signInURL: URL? {
        //let redirectURI = "http://localhost:3000."
        //let redirectURI = "spotify-ios-quick-start://spotify-login-callback"
        let base = "https://accounts.spotify.com/authorize"
        let string = "\(base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        
        return URL(string: string)
    }
    
    
    var isSigned: Bool {
        return accessToken != nil
    }
    
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        let currentDate = Date()
        let fiveMinites: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinites) >= expirationDate
    }
    
    public func exchangeCodeForToken(
        code: String,
        completion: @escaping ((Bool) -> Void)) {
            
            // Get Token
            guard let url = URL(string: Constants.tokenAPIURL) else {
                return
            }
            
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            ]
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded ", forHTTPHeaderField: "Content-Type")
            request.httpBody = components.query?.data(using: .utf8)
            let basicToken = Constants.clientID+":"+Constants.clientSecret
            let data = basicToken.data(using: .utf8)
            
            guard let base64String = data?.base64EncodedString() else {
                print("Failer to get base64")
                completion(false)
                return
            }
            request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                guard let data = data,
                      error == nil else {
                    completion(false)
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self?.cachToken(result: result)
                    print(result)
                    completion(true)
                } catch {
                    print(error.localizedDescription)
                    completion(false)
                }
            }
            task.resume()
            
        }
    
    public func refreshIfNeeded(completion: @escaping(Bool) -> Void) {
//        guard shouldRefreshToken else {
//            completion(true)
//            return
//        }

        guard let refreshToken = self.refreshToken else {
            return
        }
        
        //Refresh the token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded ", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        
        guard let base64String = data?.base64EncodedString() else {
            print("Failer to get base64")
            completion(false)
            return
        }
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data,
                  error == nil else {
                completion(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("Succcessfully Refreshed")
                self?.cachToken(result: result)
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }
    
    private func cachToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.acces_token, 
                                       forKey: "access_token")
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token,
                                           forKey: "refresh_token")
        }
       
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)),
                                       forKey: "expirationDate")
    }
    
}
