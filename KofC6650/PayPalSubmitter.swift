import Foundation

/// Submits a PayPal hosted-button "Buy Now" form the same way a browser
/// would (POST to cgi-bin/webscr with the option fields), then follows
/// PayPal's redirect to the actual checkout URL -- URLSession follows
/// redirects by default, so this needs no WebView at all. We never touch
/// card/payment entry ourselves; the resulting URL is handed off to the
/// system browser to finish checkout.
enum PayPalSubmitter {
    struct SubmissionError: Error {}

    static func submit(hostedButtonId: String, fields: [String: String]) async throws -> URL {
        var allFields = fields
        allFields["cmd"] = "_s-xclick"
        allFields["hosted_button_id"] = hostedButtonId

        var components = URLComponents()
        components.queryItems = allFields.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: URL(string: "https://www.paypal.com/cgi-bin/webscr")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let url = response.url else {
            throw SubmissionError()
        }
        return url
    }
}
