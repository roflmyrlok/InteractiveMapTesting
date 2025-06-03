//
//  AddReviewView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI
import PhotosUI

struct AddReviewView: View {
    let locationId: String
    let viewModel: ReviewViewModel
    
    @State private var rating = 3
    @State private var reviewContent = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 20) {
                        Text("How would you rate this location?")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        InteractiveRatingView(
                            rating: $rating,
                            size: 40,
                            spacing: 15
                        )
                        
                        Text(getRatingDescription(rating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } header: {
                    Text("Rating")
                }
                
                Section(header: Text("Review")) {
                    TextEditor(text: $reviewContent)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if reviewContent.isEmpty {
                                    Text("Share your experience with this location...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section(header: Text("Photos (Optional)")) {
                    if selectedImages.isEmpty {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                                Text("Add Photos")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("Up to 5 photos")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s") selected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                PhotosPicker(
                                    selection: $selectedPhotos,
                                    maxSelectionCount: 5,
                                    matching: .images
                                ) {
                                    Text("Change")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button(action: {
                                                selectedImages.remove(at: index)
                                                if index < selectedPhotos.count {
                                                    selectedPhotos.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            HStack {
                                Text("Submitting...")
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        } else {
                            Text("Submit Review")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(reviewContent.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(reviewContent.isEmpty || isSubmitting)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                    
                    if !viewModel.errorMessage.isNilOrEmpty {
                        Text(viewModel.errorMessage ?? "")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Review")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit") {
                    submitReview()
                }
                .disabled(reviewContent.isEmpty || isSubmitting)
                .foregroundColor(reviewContent.isEmpty ? .gray : .blue)
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: selectedPhotos) { newPhotos in
                loadSelectedPhotos(newPhotos)
            }
        }
    }
    
    private func getRatingDescription(_ rating: Int) -> String {
        switch rating {
        case 1:
            return "Poor - Would not recommend"
        case 2:
            return "Fair - Below expectations"
        case 3:
            return "Good - Meets expectations"
        case 4:
            return "Very Good - Above expectations"
        case 5:
            return "Excellent - Highly recommend"
        default:
            return "Rate this location"
        }
    }
    
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) {
        selectedImages.removeAll()
        
        for photo in photos {
            photo.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.selectedImages.append(image)
                        }
                    }
                case .failure(let error):
                    print("Failed to load photo: \(error)")
                }
            }
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        
        if selectedImages.isEmpty {
            viewModel.addReview(for: locationId, rating: rating, content: reviewContent) { success in
                isSubmitting = false
                
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else if let error = viewModel.errorMessage {
                    errorMessage = error
                    showError = true
                } else {
                    errorMessage = "Failed to submit your review. Please try again."
                    showError = true
                }
            }
        } else {
            viewModel.addReviewWithImages(for: locationId, rating: rating, content: reviewContent, images: selectedImages) { success in
                isSubmitting = false
                
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else if let error = viewModel.errorMessage {
                    errorMessage = error
                    showError = true
                } else {
                    errorMessage = "Failed to submit your review. Please try again."
                    showError = true
                }
            }
        }
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
}
