import Foundation

struct RecentPhotoDto: Decodable, Identifiable, Hashable {
    let id: String
    let imageUrl: String
    // Resized (max 800px wide) JPEG for grid/list display. Falls back to the
    // full-size imageUrl server-side for formats the thumbnailer can't
    // decode (real Apple HEIC), so this is always a valid URL to load.
    let thumbnailUrl: String
    let caption: String?
    let submittedBy: String?
    let uploadedAt: String?
}

struct ArchiveMonthDto: Decodable, Identifiable, Hashable {
    let month: String
    let label: String
    let count: Int

    var id: String { month }
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
