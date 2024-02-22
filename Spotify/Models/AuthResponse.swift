//
//  AuthResponse.swift
//  Spotify
//
//  Created by Mohamed on 18/02/2024.
//

import Foundation

struct AuthResponse: Codable {
    
    let acces_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope : String
    let token_type: String
    
}
