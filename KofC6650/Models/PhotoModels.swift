import Foundation

struct RecentPhotoDto: Decodable, Identifiable, Hashable {
    let id: String
    let imageUrl: String
    let caption: String?
    let submittedBy: String?
    let uploadedAt: String?
}

struct PhotoUploadFile {
    let data: Data
    let mimeType: String
}

struct PhotoUploadResponseDto: Decodable {
    let ok: Bool
    let saved: Int
    let skipped: Int
}

struct UploadErrorResponseDto: Decodable {
    let error: String?
}

struct PhotoUploadException: Error {
    let message: String
}
