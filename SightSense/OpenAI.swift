//
//  OpenAI.swift
//  SightSense
//
//  Created by Peter Zhao & Owen Gregson on 4/6/24.
//

import Foundation
import CoreImage
import UIKit
import AVFoundation

class OpenAIWrapper: NSObject{
    
    
    
    let apiKey: String = ((Bundle.main.infoDictionary?["OPENAI_KEY"] as? String?)!!).replacingOccurrences(of: "\"", with: "")
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request: URLRequest
    
    
    override init() {
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        super.init()
    }
    
    func promptsForImage(abstraction: abstraction) -> String{
        let basePrompt = "Provide a description of this image for a blind person, including the relative location of objects in the image. Imagine you are talking to the blind person and write it in that tense. Avoid directly referencing the image in your sentences such as \"in the corner of the image\" or \"in the scene\" and instead talk to the blind person such as \"in the bottom left corner.\" Be confident in your description, avoiding phrases like 'looks like' or 'seems like' or 'resembles.' Make sure your description is very analytical. Do not talk about the atmosphere such as 'cozy' or 'lived-in.' Do not explain the color of objects and things. If it is too difficult to undestand the picture, you can ask the user to try and move towards a certain direction to get a better capture, but only use this if you really have no idea what is happening in the image. There is no need to talk about how the picture is taken such as the perspective or angle. Ensure that you get these three parts of the image described: 1. The Scene (indoor/outdoor, room/park etc.) 2. The Significant Objects 3. The details of significant objects."
        
        switch abstraction{
        case .summarized: return basePrompt + " Make the description summarized and quite simple, only 1-2 brief sentences in length and only explaining the most important parts of the image for the person to know."
        case .basic: return basePrompt + " Make the description 2-3 concise sentences in length, prioritizing the most important parts of the image over insignificant ones."
        case .enhanced: return basePrompt + " Make the description extra detailed, approximately 3-4 sentences in length."
        }
    }
    
    func imageRequestPayload(base64Image: String, prompt: String, detail: String = "low", maxTokens: Int = 300) -> [String : Any]{
        let payload = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64," + base64Image,
                                "detail": detail
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": maxTokens
        ] as! [String : Any]
        return payload
    }
    
    func textRequestPayload(text: String, model: String, maxTokens: Int = 100) -> [String: Any]{
        let payload = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": text
                        ]
                    ]
                ]
            ],
            "max_tokens": maxTokens
        ] as! [String : Any]
        return payload
    }

    
    func convertImageToBase64(input: CIImage, direction: AVCaptureVideoOrientation = .portrait) -> String{
        let context = CIContext()
        let cgImage = context.createCGImage(input, from: input.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return (uiImage.jpegData(compressionQuality: 1)?.base64EncodedString())!
    }
    
    func makeRequest(payload: [String: Any], completion: @escaping (String) -> Void) {
        guard let requestBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion("Error: Could not serialize payload")
            return
        }

        request.httpBody = requestBody
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("Error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(self.descriptionForStatusCode(httpResponse.statusCode))
                return
            }

            guard let data = data else {
                completion("Error: No data received")
                return
            }

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let finalResponse = firstChoice["message"] as? [String: Any],
                   let content = finalResponse["content"] as? String {
                    completion(content)
                } else {
                    completion("Error: Failed to parse JSON")
                }
            } catch {
                completion("Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func descriptionForStatusCode(_ statusCode: Int) -> String {
        switch statusCode {
        case 100...199:
            return "Informational: \(statusCode)"
        case 200:
            return "Success: OK"
        case 201:
            return "Success: Created"
        case 202:
            return "Success: Accepted"
        case 203:
            return "Success: Non-Authoritative Information"
        case 204:
            return "Success: No Content"
        case 205:
            return "Success: Reset Content"
        case 206:
            return "Success: Partial Content"
        case 300...399:
            return "Redirection: \(statusCode)"
        case 400:
            return "Client Error: Bad Request"
        case 401:
            return "Client Error: Unauthorized"
        case 402:
            return "Client Error: Payment Required"
        case 403:
            return "Client Error: Forbidden"
        case 404:
            return "Client Error: Not Found"
        case 405:
            return "Client Error: Method Not Allowed"
        case 406:
            return "Client Error: Not Acceptable"
        case 407:
            return "Client Error: Proxy Authentication Required"
        case 408:
            return "Client Error: Request Timeout"
        case 409:
            return "Client Error: Conflict"
        case 410:
            return "Client Error: Gone"
        case 411:
            return "Client Error: Length Required"
        case 412:
            return "Client Error: Precondition Failed"
        case 413:
            return "Client Error: Payload Too Large"
        case 414:
            return "Client Error: URI Too Long"
        case 415:
            return "Client Error: Unsupported Media Type"
        case 416:
            return "Client Error: Range Not Satisfiable"
        case 417:
            return "Client Error: Expectation Failed"
        case 418:
            return "Client Error: I'm a teapot"
        case 500...599:
            return "Server Error: \(statusCode)"
        default:
            return "Unknown Status Code: \(statusCode)"
        }
    }
}
