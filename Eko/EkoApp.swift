//
//  EkoApp.swift
//  Eko
//
//  Created by Ryan York on 10/10/25.
//

import SwiftUI

@main
struct EkoApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    // Main app content (to be implemented)
                    ContentView()
                } else {
                    // Authentication flow
                    LoginView(viewModel: authViewModel)
                }
            }
            .onOpenURL { url in
                // Handle OAuth callback from Supabase
                Task {
                    await authViewModel.handleOAuthCallback(url: url)
                }
            }
        }
    }
}
