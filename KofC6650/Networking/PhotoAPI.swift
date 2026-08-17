import Foundation

enum PhotoAPI {
    private static let recentPhotosURL = URL(string: "https://koc-photos.erdcloud.org/api/photos")!
    private static let uploadURL = URL(string: "https://koc-photos.erdcloud.org/api/upload")!
    private static let archiveMonthsURL = URL(string: "https://koc-photos.erdcloud.org/api/photos/archive")!
    private static let archiveBaseURL = "https://koc-photos.erdcloud.org/api/photos/archive"

    static func fetchRecentPhotos() async throws -> [RecentPhotoDto] {
        let (data, response) = try await URLSession.shared.data(from: recentPhotosURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([RecentPhotoDto].self, from: data)
    }

    static func fetchArchiveMonths() async throws -> [ArchiveMonthDto] {
        let (data, response) = try await URLSession.shared.data(from: archiveMonthsURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([ArchiveMonthDto].self, from: data)
    }

    static func fetchArchivedPhotos(month: String) async throws -> [RecentPhotoDto] {
        guard let url = URL(string: "\(archiveBaseURL)/\(month)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([RecentPhotoDto].self, from: data)
    }

    /// Hand-built multipart/form-data body (Swift has no built-in multipart
    /// helper). Field order matters: pin, name, caption, then one `photos`
    /// part per image with filename="photo_<index>.<ext>" and the real
    /// per-file Content-Type -- must match the server's expectations exactly.
    static func uploadPhotos(
        pin: String,
        name: String,
        caption: String,
        photos: [PhotoUploadFile]
    ) async throws -> PhotoUploadResponseDto {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField(name: "pin", value: pin)
        appendField(name: "name", value: name)
        appendField(name: "caption", value: caption)

        for (index, photo) in photos.enumerated() {
            let rawExt = photo.mimeType.split(separator: "/").last.map(String.init) ?? ""
            let ext = rawExt.isEmpty ? "jpg" : rawExt
            let filename = "photo_\(index).\(ext)"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\r\n"
                    .data(using: .utf8)!
            )
            body.append("Content-Type: \(photo.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(photo.data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let http = response as? HTTPURLResponse else {
            throw PhotoUploadException(message: "Upload failed")
        }
        guard (200...299).contains(http.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(UploadErrorResponseDto.self, from: data),
               let message = errorResponse.error {
                throw PhotoUploadException(message: message)
            }
            throw PhotoUploadException(message: "Upload failed (HTTP \(http.statusCode))")
        }

        return try JSONDecoder().decode(PhotoUploadResponseDto.self, from: data)
    }
}
