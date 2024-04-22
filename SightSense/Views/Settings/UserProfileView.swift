//
//  UserProfileView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI

struct PersonalDetailsView: View {
    @State private var firstName: String = UserDefaultsManager.shared.string(forKey: "firstName", defaultValue: "SightSense")
    @State private var lastName: String = UserDefaultsManager.shared.string(forKey: "lastName", defaultValue: "User")
    @State private var userEmail: String = UserDefaultsManager.shared.string(forKey: "userEmail", defaultValue: "business@sightsense.ai")
    
    var body: some View {
        Form {
            HStack {
                Text("First Name")
                Spacer(minLength: 45)
                TextField("First Name", text: $firstName)
                    .multilineTextAlignment(.leading)
                    .submitLabel(.done)
                    .textInputAutocapitalization(TextInputAutocapitalization.words)
                    .onSubmit {
                        UserDefaultsManager.shared.set(self.firstName, forKey: "firstName")
                    }
            }
            HStack {
                Text("Last Name")
                Spacer(minLength: 45)
                TextField("Last Name", text: $lastName)
                    .multilineTextAlignment(.leading)
                    .textInputAutocapitalization(TextInputAutocapitalization.words)
                    .submitLabel(.done)
                    .onSubmit {
                        UserDefaultsManager.shared.set(self.lastName, forKey: "lastName")
                    }
            }
            HStack {
                Text("Email")
                Spacer(minLength: 85)
                TextField("Email", text: $userEmail)
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(TextInputAutocapitalization.never)
                    .foregroundColor(.gray)
                    .submitLabel(.done)
                    .onSubmit {
                        UserDefaultsManager.shared.set(self.userEmail, forKey: "userEmail")
                    }
                    .disabled(true)
            }
            Section {
                Button("Delete Account") {
                }
                .foregroundColor(.red)
            }
        }
    }
}

struct EmailSwitchView: View {
    var body: some View {
        Text("View Example")
    }
}

struct PasswordSwitchView: View {
    var body: some View {
        Text("View Example")
    }
}

