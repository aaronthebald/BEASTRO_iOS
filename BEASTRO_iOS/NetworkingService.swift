//
//  NetworkingService.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

class NetworkingService {
    private let urlString = "https://purs-demo-bucket-test.s3.us-west-2.amazonaws.com/location.json"
    private var jsonDecoder = JSONDecoder()
    
    enum URLError: Error {
        case invalidURL
        case badResponse
    }
    
    func fetchBusinessHours() async throws -> [Hour] {
        var retunedArray: [Hour] = []
        guard let url = URL(string: urlString) else {
            let error = URLError.invalidURL
            throw error
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
//            TODO: Come back and include edge cases
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError.badResponse
            }
            var decodedData = try jsonDecoder.decode(HoursResponse.self, from: data)
            retunedArray = decodedData.hours
        } catch {
            throw error
        }
        return retunedArray
    }
}

