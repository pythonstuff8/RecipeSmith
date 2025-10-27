import Foundation
import AWSS3
import Smithy
import AWSClientRuntime
#if canImport(Darwin)
import Darwin
#endif

enum APIError: Error {
    case invalidResponse
    case badStatusCode(Int)
    case emptyContent
    case encodingError
    case decodingError
    case missingData
    case unknown
}

class APIService {
    static let shared = APIService()
    
    private let openAIKey = Configuration.openAIKey
    private let googleAPIKey = Configuration.googleAPIKey
    private let bucketName = Configuration.awsBucketName
    private let region = Configuration.awsRegion

    private let s3Client: S3Client

    private init() {
        if !Configuration.awsAccessKey.isEmpty && !Configuration.awsSecretKey.isEmpty {
            #if canImport(Darwin)
            setenv("AWS_ACCESS_KEY_ID", Configuration.awsAccessKey, 1)
            setenv("AWS_SECRET_ACCESS_KEY", Configuration.awsSecretKey, 1)

            setenv("AWS_REGION", region, 1)
            #endif
        } else {
            print("No Creds")
        }

        do {
            self.s3Client = try S3Client(region: self.region)
        } catch {
            fatalError("Failed to initialize S3Client: \(error)")
        }
    }
    
    func uploadToS3(imageData: Data, fileName: String) async throws -> String {
        print("Starting S3 upload process")
        print("File size: \(imageData.count) bytes")
        
        let input = PutObjectInput(
            body: .data(imageData),
            bucket: bucketName,
            contentType: "image/png",
            key: fileName
        )
        print("Prepared S3 upload input for bucket: \(bucketName)")
        
        do {
            print("Initiating S3 putObject request")
            let result = try await s3Client.putObject(input: input)
            print("S3 putObject successful: \(result)")
            
            let url = "https://\(bucketName).s3.\(region).amazonaws.com/\(fileName)"
            print("Generated S3 URL: \(url)")
            return url
        } catch {
            print("S3 upload failed: \(error.localizedDescription)")
            throw APIError.unknown
        }
    }
    
    func deleteFromS3(fileName: String) async throws {
        let input = DeleteObjectInput(
            bucket: bucketName,
            key: fileName
        )
        
        do {
            _ = try await s3Client.deleteObject(input: input)
        } catch {
        }
    }
    
    func clearS3Bucket() async throws {
        let listInput = ListObjectsV2Input(bucket: bucketName)
        let listOutput = try await s3Client.listObjectsV2(input: listInput)
        
        guard let objects = listOutput.contents, !objects.isEmpty else {
            return
        }
        
        let objectsToDelete = objects.compactMap { $0.key }.map { S3ClientTypes.ObjectIdentifier(key: $0) }
        
        let deleteInput = DeleteObjectsInput(
            bucket: bucketName,
            delete: .init(objects: objectsToDelete)
        )
        
        do {
            _ = try await s3Client.deleteObjects(input: deleteInput)
        } catch {
        }
    }
    
    
    func generateRecipe(prompt: String) async throws -> Recipe {
        print("Starting recipe generation process")
         var recipe = try await generateRecipeData(prompt: prompt)
        print("Successfully generated base recipe data")
        
        if let imageDescription = recipe.imageDescription, !imageDescription.isEmpty {
            print("Starting image generation with description: \(imageDescription)")
            do {
                let imageData = try await generateImage(prompt: imageDescription)
                print("Successfully generated image data")
                
                if let imageBytes = Data(base64Encoded: imageData) {
                    let uniqueId = UUID().uuidString.prefix(8)
                    let fileName = "\(recipe.title.replacingOccurrences(of: " ", with: "_"))_\(uniqueId).png"
                    print("Preparing to upload image with filename: \(fileName)")
                    
                    let imageUrl = try await uploadToS3(imageData: imageBytes, fileName: fileName)
                    print("Successfully uploaded image to S3: \(imageUrl)")
                    
                    var updatedRecipe = recipe
                    updatedRecipe.imageName = fileName
                    updatedRecipe.imageUrl = imageUrl
                    print("Recipe updated with image details")
                    return updatedRecipe
                } else {
                    print("Error: Failed to decode base64 image data")
                }
            } catch {
                print("Error during image generation/upload: \(error.localizedDescription)")
                return recipe
            }
        } else {
            print("No image description provided, skipping image generation")
        }
        
        return recipe
    }
    
    func generateRecipeData(prompt: String) async throws -> Recipe {
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        let systemPrompt = """
        You are a culinary expert. Return recipe data in strict JSON format.
        
        You MUST follow these rules:
        1. Return ONLY a JSON object with NO additional text
        2. ALL fields listed below are required and must not be empty
        3. Time fields MUST include "minutes" (e.g. "15 minutes")
        4. Calorie count MUST be a number as string (e.g. "450")
        5. Macros MUST include "g" unit (e.g. "45g")
        6. Include at least one diet label and equipment item
        7. DO NOT include step numbers in instructions
        
        Required JSON format:
        {
          "cuisine": "string",
          "title": "string",
          "description": "string",
          "imgdesc": "string",
          "servings": "string",
          "prep": "string with minutes",
          "cook": "string with minutes",
          "total": "string with minutes",
          "cal": "number as string",
          "macros": {
            "protein": "string with g",
            "carbohydrates": "string with g",
            "fat": "string with g"
          },
          "ingredients": ["string"],
          "instructions": ["string"],
          "meal": "string",
          "equipment": ["string"],
          "diet": ["string"]
        }
        """
        
        let payload: [String: Any] = [
            "model": "gpt-4.1-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.badStatusCode((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = decodedResponse.choices?.first?.message.content else {
            throw APIError.emptyContent
        }
        
        let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw APIError.encodingError
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let recipe = try decoder.decode(Recipe.self, from: jsonData)
            
            guard 
                !recipe.prepTime.isEmpty && recipe.prepTime.contains("minute"),
                !recipe.cookTime.isEmpty && recipe.cookTime.contains("minute"),
                !recipe.totalTime.isEmpty && recipe.totalTime.contains("minute"),
                !recipe.calorieCount.isEmpty && Int(recipe.calorieCount) != nil,
                !recipe.dietLabels.isEmpty,
                !recipe.equipmentUsed.isEmpty,
                !recipe.macros.protein.isEmpty && recipe.macros.protein.contains("g"),
                !recipe.macros.carbohydrates.isEmpty && recipe.macros.carbohydrates.contains("g"),
                !recipe.macros.fat.isEmpty && recipe.macros.fat.contains("g")
            else {
                throw APIError.decodingError
            }
            
            return recipe
        } catch {
            throw APIError.decodingError
        }
    }
    
    func generateImage(prompt: String) async throws -> String {
        print("Starting image generation")
        print("Using prompt: \(prompt)")
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(googleAPIKey, forHTTPHeaderField: "x-goog-api-key")
        
        print("Preparing API request payload")
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ]
         ]
        
         request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        print("Sending request to Gemini API")
        
         let (data, response) = try await URLSession.shared.data(for: request)
        
         guard let httpResponse = response as? HTTPURLResponse else {
            print("Network error: Invalid HTTP response")
             throw APIError.invalidResponse
         }
        
        print("Received response with status code: \(httpResponse.statusCode)")
        print("Response body size: \(data.count) bytes")
        
         if httpResponse.statusCode == 200 {
             do {
                print("Parsing successful response")

                let anyJson = try JSONSerialization.jsonObject(with: data)
                print("JSON deserialized to Any")

                guard let json = anyJson as? [String: Any] else {
                    print("JSON root is not a dictionary")
                     throw APIError.decodingError
                 }
                print("JSON cast to [String: Any]")

                let candidates = json["candidates"] as? [[String: Any]]
                print("Extracted candidates")

                let candidate = candidates?.first
                print("Extracted first candidate")

                let content = candidate?["content"] as? [String: Any]
                print("Extracted content")

                let parts = content?["parts"] as? [[String: Any]]
                print("Extracted parts")

                let inlineDataPart = (parts?.count ?? 0) > 1 ? parts?[1] : nil
                print("Extracted inlineData part")

                let inlineData = inlineDataPart?["inlineData"] as? [String: Any]
                print("Extracted inlineData")

                let base64Data = inlineData?["data"] as? String
                print("Extracted base64 data")

                if let base64Data = base64Data {
                    return base64Data
                } else {
                    print(" Missing base64 data in response")
                     throw APIError.missingData
                 }
            } catch {
                print(" Error decoding response: \(error.localizedDescription)")
                 throw APIError.decodingError
             }
         }
        
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = errorJson["error"] as? [String: Any],
           let message = error["message"] as? String {
            print(" Server error: \(message)")
         }
        
        print(" Invalid response structure")
         throw APIError.unknown
     }
    
    private func parseRecipeJSON(_ jsonString: String) -> Recipe? {
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "```")
            if let startRange = cleaned.range(of: "```") {
                var remainder = String(cleaned[startRange.upperBound...])
                if let endRange = remainder.range(of: "```", options: [.backwards]) {
                    remainder = String(remainder[..<endRange.lowerBound])
                }
                cleaned = remainder
            }
        }

        guard let data = cleaned.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(Recipe.self, from: data)
    }
}



struct OpenAIResponse: Codable {
    let choices: [Choice]?
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct ImageGenerationResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let inlineData: InlineData?
                
                struct InlineData: Codable {
                    let data: String
                }
            }
        }
    }
}

