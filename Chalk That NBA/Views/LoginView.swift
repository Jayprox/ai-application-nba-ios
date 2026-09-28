//
//  LoginView.swift
//  Chalk That NBA
//
//  Username + password only (no signup; JD creates accounts). Layout and
//  wording follow the web's pages/Login.jsx: a card with the wordmark,
//  "Sign in", two fields, an error line in the accent color, and a
//  "Sign in" / "Signing in…" button. Structure copied from the NFL app.
//
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field { case username, password }

    private var canSubmit: Bool { !username.isEmpty && !password.isEmpty && !auth.isLoading }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Wordmark(size: 30)
                        .frame(maxWidth: .infinity)

                    Text("Sign in")
                        .font(.brandBody(.title3, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity)

                    field(title: "Username", text: $username, isSecure: false, contentType: .username, field: .username)
                    field(title: "Password", text: $password, isSecure: true, contentType: .password, field: .password)

                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .font(.brandBody(.subheadline, weight: .medium))
                            .foregroundStyle(Color.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: submit) {
                        Text(auth.isLoading ? "Signing in…" : "Sign in")
                            .font(.brandBody(.body, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .background(Color.accent)
                    .foregroundStyle(Color.onAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(!canSubmit)
                    .opacity(canSubmit || auth.isLoading ? 1 : 0.6)
                }
                .padding(28)
                .background(Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: 400)
                .padding(.horizontal, 16)
                .padding(.top, 80)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { focusedField = .username }
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        Task { await auth.login(username: username, password: password) }
    }

    private func field(
        title: String,
        text: Binding<String>,
        isSecure: Bool,
        contentType: UITextContentType,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.brandBody(.subheadline, weight: .semibold))
                .foregroundStyle(Color.ink)

            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .textContentType(contentType)
            .focused($focusedField, equals: field)
            .submitLabel(field == .username ? .next : .go)
            .onSubmit {
                if field == .username { focusedField = .password } else { submit() }
            }
            .accessibilityLabel(title)
            .font(.brandBody(.body))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(focusedField == field ? Color.link : Color.field, lineWidth: focusedField == field ? 2 : 1)
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
