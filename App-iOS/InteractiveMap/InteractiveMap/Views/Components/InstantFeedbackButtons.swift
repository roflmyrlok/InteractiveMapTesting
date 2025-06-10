//
//  InstantFeedbackButtons.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 10.06.2025.
//

import SwiftUI

struct InstantFeedbackButtons: View {
    let locationId: String
    let isAuthenticated: Bool
    @State private var isSubmitting = false
    @State private var showingLoginPrompt = false
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    @State private var showingErrorMessage = false
    @State private var errorMessage = ""
    @State private var selectedFeedbackType: InstantFeedbackType?
    
    private let instantFeedbackService = InstantFeedbackService()
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Quick Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text("Help others know the current status of this shelter")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 12) {
                ForEach(InstantFeedbackType.allCases, id: \.rawValue) { feedbackType in
                    InstantFeedbackButton(
                        feedbackType: feedbackType,
                        isSelected: selectedFeedbackType == feedbackType,
                        isSubmitting: isSubmitting
                    ) {
                        submitFeedback(feedbackType)
                    }
                }
            }
            
            if isSubmitting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Submitting...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .alert("Login Required", isPresented: $showingLoginPrompt) {
            Button("OK") { }
        } message: {
            Text("You need to be logged in to submit instant feedback.")
        }
        .alert("Success", isPresented: $showingSuccessMessage) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showingErrorMessage) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitFeedback(_ feedbackType: InstantFeedbackType) {
        if !isAuthenticated {
            showingLoginPrompt = true
            return
        }
        
        isSubmitting = true
        selectedFeedbackType = feedbackType
        
        instantFeedbackService.submitInstantFeedback(
            locationId: locationId,
            feedbackType: feedbackType
        ) { success, message in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if success {
                    successMessage = message ?? "Feedback submitted successfully!"
                    showingSuccessMessage = true
                    
                    // Keep the selected state for a moment to show user what they selected
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        selectedFeedbackType = nil
                    }
                } else {
                    errorMessage = message ?? "Failed to submit feedback. Please try again."
                    showingErrorMessage = true
                    selectedFeedbackType = nil
                }
            }
        }
    }
}

struct InstantFeedbackButton: View {
    let feedbackType: InstantFeedbackType
    let isSelected: Bool
    let isSubmitting: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        switch feedbackType {
        case .allGood:
            return .green
        case .problemInside:
            return .orange
        case .cantGetIn:
            return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? buttonColor : Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if isSubmitting && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: feedbackType.icon)
                            .font(.title2)
                            .foregroundColor(isSelected ? .white : buttonColor)
                    }
                }
                
                Text(feedbackType.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? buttonColor : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .disabled(isSubmitting)
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
