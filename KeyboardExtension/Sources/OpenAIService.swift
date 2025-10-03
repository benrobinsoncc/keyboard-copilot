import Foundation

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case networkError(Error)
}

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func complete(prompt: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(.invalidResponse))
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let error = json["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
            }
        }.resume()
    }

    // Feature-specific methods with tailored prompts
    func compose(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = "Based on this brief input: '\(inputText)', compose a clear, well-written message. Expand on the idea naturally and make it sound professional yet friendly. Only return the composed message, nothing else."
        complete(prompt: prompt, completion: completion)
    }

    func polish(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = "Polish this text to make it more professional and well-written: '\(inputText)'. Keep the same meaning but improve clarity, grammar, and tone. Only return the polished text, nothing else."
        complete(prompt: prompt, completion: completion)
    }

    func shorten(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = "Make this text more concise while keeping the key message: '\(inputText)'. Only return the shortened text, nothing else."
        complete(prompt: prompt, completion: completion)
    }

    func explain(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = "Explain this in simple, clear terms: '\(inputText)'. Provide a concise explanation that's easy to understand. Keep it to 2-3 sentences. Only return the explanation, nothing else."
        complete(prompt: prompt, completion: completion)
    }

    func factCheck(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = "Fact-check this statement: '\(inputText)'. Provide a brief assessment (true/false/partially true) and a short explanation. Keep it concise (2-3 sentences). Only return the fact-check result, nothing else."
        complete(prompt: prompt, completion: completion)
    }
}
