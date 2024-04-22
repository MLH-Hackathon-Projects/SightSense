//
//  LanguageConfigurationView.swift
//  SightSense
//
//  Created by Owen Gregson on 4/6/24.
//

import SwiftUI
import Combine

struct Language: Identifiable, Hashable {
    let id: String
    let displayName: String
}

struct LanguagePickerView: View {
    @State private var searchText = ""
    @State private var selectedLanguageId = UserDefaults.standard.string(forKey: "inputLanguage") ?? "English"
    var languages: [Language]
    var saveKey: String
    
    var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            List(filteredLanguages, id: \.id) { language in
                LanguageCell(language: language.displayName, isSelected: selectedLanguageId == language.id)
                    .onTapGesture {
                        self.selectedLanguageId = language.id
                        UserDefaults.standard.set(language.id, forKey: saveKey)
                    }
            }
        }
        .navigationBarTitle("Primary language", displayMode: .large)
    }
}

struct LanguageCell: View {
    var language: String
    var isSelected: Bool

    var body: some View {
        HStack {
            Text(language)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

struct PickInputLanguageView: View {
    var body: some View {
        NavigationView {
            LanguagePickerView(languages: [
                Language(id: "English", displayName: "English"),
                Language(id: "Chinese", displayName: "中文"),
                Language(id: "Spanish", displayName: "Español"),
                // Add all languages here
            ], saveKey: "inputLanguage")
        }
    }
}

struct PickOutputLanguageView: View {
    var body: some View {
        NavigationView {
            LanguagePickerView(languages: [
                Language(id: "English", displayName: "English"),
                Language(id: "Chinese", displayName: "中文"),
                Language(id: "Spanish", displayName: "Español"),
                // Add all languages here
            ], saveKey: "outputLanguage")
        }
    }
}
