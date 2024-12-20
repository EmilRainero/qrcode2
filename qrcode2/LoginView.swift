import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var loginError: String? = nil
    @State private var isLoggedIn: Bool = false

    var body: some View {
        
        VStack {
            
            if isLoggedIn {
                MainView(onLogout: {
                    logout()
                })
            } else {
                VStack(spacing: 20) {
                    Text("Home Laser Range")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer().frame(height: 40)
                    
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let error = loginError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }

                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.horizontal)

                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .autocapitalization(.none)
                        } else {
                            SecureField("Password", text: $password)
                        }

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                    Button(action: {
                        authenticateUser()
                    }) {
                        Text("Login")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Image(uiImage: UIImage(named: "loginimage")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }

    private func authenticateUser() {
        // Placeholder authentication logic
        if username.isEmpty || password.isEmpty {
            loginError = "Please enter both username and password."
        } else if username == "test" && password == "password" {
            loginError = nil
            isLoggedIn = true
            print("Login successful")
        } else {
            loginError = "Invalid username or password."
        }
    }
    
    private func logout() {
        username = ""
        password = ""
        isLoggedIn = false
    }
}
