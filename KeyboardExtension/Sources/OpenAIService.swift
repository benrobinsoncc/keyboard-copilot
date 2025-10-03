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

    func complete(prompt: String, temperature: Double = 0.7, maxTokens: Int = 500, completion: @escaping (Result<String, OpenAIError>) -> Void) {
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
            "temperature": temperature,
            "max_tokens": maxTokens
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
        let prompt = """
        Take this quick note and turn it into a complete message: '\(inputText)'

        Expand it naturally while keeping the original vibe. Write it in plain English - professional but casual and friendly, like you're texting a colleague.

        IMPORTANT:
        - Preserve any lists, bullet points, or formatting structure from the input
        - If input has line breaks or list structure, maintain that formatting
        - Don't add greetings (like "Hey [name]"), sign-offs (like "Best, [name]"), or any email formatting
        - Just return the core message content itself, nothing else
        """
        complete(prompt: prompt, temperature: 0.8, completion: completion)
    }

    func polish(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = """
        Clean up this text: '\(inputText)'

        Fix any grammar issues, improve clarity, and make it sound better while keeping the same meaning and tone. Write it in plain English - professional but casual and conversational.

        IMPORTANT: Don't add greetings, sign-offs, or email formatting. Just improve the existing text as-is and return only that.
        """
        complete(prompt: prompt, temperature: 0.5, completion: completion)
    }

    func shorten(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = """
        Make this way shorter: '\(inputText)'

        Cut out the fluff and get straight to the point. Keep it casual and conversational - plain English that sounds natural.

        IMPORTANT: Don't add greetings, sign-offs, or email formatting. Just return the shortened core message, nothing else.
        """
        complete(prompt: prompt, temperature: 0.5, completion: completion)
    }

    func explain(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = """
        Explain this in simple terms: '\(inputText)'

        Break it down so anyone can understand it. Use plain, everyday English - casual but clear. Keep it to 2-3 sentences. Just return the explanation, no preamble.
        """
        complete(prompt: prompt, maxTokens: 300, completion: completion)
    }

    func factCheck(inputText: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = """
        Fact-check this: '\(inputText)'

        Start with your verdict (True/False/Partially True/Misleading), then explain why in 1-2 sentences. Keep it casual and conversational - plain English that's easy to follow. Just return the fact-check, no extra commentary.
        """
        complete(prompt: prompt, maxTokens: 300, completion: completion)
    }
}
