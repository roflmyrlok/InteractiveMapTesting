//
//  AddReviewView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

// App-iOS/InteractiveMap/InteractiveMap/Views/Review/AddReviewView.swift
import SwiftUI

struct AddReviewView: View {
    let locationId: String
    let viewModel: ReviewViewModel
    
    @State private var rating = 3
    @State private var reviewContent = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Rating")) {
                HStack {
                    Text("Your rating:")
                    Spacer()
                    RatingView(rating: rating, size: 24)
                        .padding(.vertical, 8)
                }
                
                Picker("Select a rating", selection: $rating) {
                    ForEach(1...5, id: \.self) { number in
                        Text("\(number) star\(number == 1 ? "" : "s")")
                            .tag(number)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Review")) {
                TextEditor(text: $reviewContent)
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if reviewContent.isEmpty {
                                Text("Write your review here...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
            }
            
            Section {
                Button(action: submitReview) {
                    if isSubmitting {
                        HStack {
                            Text("Submitting...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Submit Review")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
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
        .navigationBarItems(trailing: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        
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
    }
}

// Extension to check if string is nil or empty
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
}
