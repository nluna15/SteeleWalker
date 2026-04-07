import FirebaseStorage
import UIKit

struct StorageService {

    /// Uploads a dog profile photo to Firebase Storage and returns the download URL.
    /// The image is resized and compressed before upload.
    static func uploadDogPhoto(dogId: String, imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData),
              let jpeg = resized(image, maxDimension: 800).jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImageData
        }

        let ref = Storage.storage().reference().child("dogs/\(dogId)/photo.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(jpeg, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Private

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    enum StorageError: LocalizedError {
        case invalidImageData

        var errorDescription: String? {
            switch self {
            case .invalidImageData:
                return "The selected image could not be processed."
            }
        }
    }
}
