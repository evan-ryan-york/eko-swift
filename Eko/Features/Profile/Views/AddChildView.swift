import SwiftUI
import EkoCore
import EkoKit

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var age: Int = 8
    @State private var selectedTemperament: Temperament = .easygoing
    @State private var talkativeScore: Double = 5
    @State private var sensitivityScore: Double = 5
    @State private var accountabilityScore: Double = 5

    // UI state
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false

    private let supabase = SupabaseService.shared
    var onChildCreated: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Information
                Section("Basic Information") {
                    TextField("Child's Name", text: $name)
                        .autocorrectionDisabled()

                    Picker("Age", selection: $age) {
                        ForEach(6...16, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                }

                // MARK: - Temperament Type
                Section {
                    Picker("Temperament", selection: $selectedTemperament) {
                        ForEach(Temperament.allCases, id: \.self) { temperament in
                            Text(temperament.displayName).tag(temperament)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedTemperament.description)
                        .font(.ekoCaption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, .ekoSpacingXS)
                } header: {
                    Text("Temperament Type")
                } footer: {
                    Text("This helps Lyra provide more personalized guidance")
                        .font(.ekoCaption)
                }

                // MARK: - Temperament Scores
                Section {
                    VStack(alignment: .leading, spacing: .ekoSpacingMD) {
                        // Talkative
                        VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                            HStack {
                                Text("How Talkative")
                                Spacer()
                                Text("\(Int(talkativeScore))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.ekoBody)

                            Slider(value: $talkativeScore, in: 1...10, step: 1)
                                .tint(.ekoPrimary)

                            HStack {
                                Text("Quiet")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Very Talkative")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // Sensitivity
                        VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                            HStack {
                                Text("Emotional Sensitivity")
                                Spacer()
                                Text("\(Int(sensitivityScore))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.ekoBody)

                            Slider(value: $sensitivityScore, in: 1...10, step: 1)
                                .tint(.ekoPrimary)

                            HStack {
                                Text("Low")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("High")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // Accountability
                        VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                            HStack {
                                Text("Takes Accountability")
                                Spacer()
                                Text("\(Int(accountabilityScore))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.ekoBody)

                            Slider(value: $accountabilityScore, in: 1...10, step: 1)
                                .tint(.ekoPrimary)

                            HStack {
                                Text("Low")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("High")
                                    .font(.ekoCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, .ekoSpacingXS)
                } header: {
                    Text("Temperament Details (Optional)")
                } footer: {
                    Text("These scores help Lyra understand your child's communication style")
                        .font(.ekoCaption)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChild()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK") { }
            } message: { error in
                Text(error.localizedDescription)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }

    // MARK: - Actions

    private func saveChild() async {
        guard !name.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            print("🔵 Attempting to create child:")
            print("  Name: \(name)")
            print("  Age: \(age)")
            print("  Temperament: \(selectedTemperament.rawValue)")
            print("  Talkative: \(Int(talkativeScore))")
            print("  Sensitivity: \(Int(sensitivityScore))")
            print("  Accountability: \(Int(accountabilityScore))")

            let child = try await supabase.createChild(
                name: name,
                age: age,
                temperament: selectedTemperament,
                temperamentTalkative: Int(talkativeScore),
                temperamentSensitivity: Int(sensitivityScore),
                temperamentAccountability: Int(accountabilityScore)
            )

            print("✅ Child created successfully: \(child.id)")

            // Success - dismiss and notify parent
            dismiss()
            onChildCreated?()

        } catch {
            print("❌ Error creating child: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error: \(decodingError)")
            }
            self.error = error
            self.showError = true
        }
    }
}

#Preview {
    AddChildView()
}
