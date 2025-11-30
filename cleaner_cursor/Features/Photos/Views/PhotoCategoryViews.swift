import SwiftUI
import Photos

// MARK: - Thumbnail View (Reusable)

struct ThumbnailView: View {
    let asset: PhotoAsset
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(AppColors.backgroundCard)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                            .scaleEffect(0.6)
                    )
            }
        }
        .clipped()
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        PhotoService.shared.loadThumbnail(
            for: asset.asset,
            size: CGSize(width: 200, height: 200)
        ) { img in
            self.image = img
        }
    }
}

// MARK: - Preview

struct PhotoCategoryViews_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView(asset: PhotoAsset(asset: PHAsset()))
    }
}
