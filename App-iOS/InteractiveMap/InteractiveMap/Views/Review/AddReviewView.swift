//
//  AddReviewView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct AddReviewView: View {
    let locationId: String
    let viewModel: ReviewViewModel
    
    @State private var rating = 3
    @State private var reviewContent = ""
    @State private var isSubmitting = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")) {
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { number in
                            Text("\(number)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Review")) {
                    TextEditor(text: $reviewContent)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Review")
                        }
                    }
                    .disabled(reviewContent.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Review")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        
        viewModel.addReview(for: locationId, rating: rating, content: reviewContent) { success in
            isSubmitting = false
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
