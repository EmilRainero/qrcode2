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
                        .disableAutocorrection(true)
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
        .onAppear {
            checkAuthenticationStatus()
        }
    }

    private func authenticateUser() {
        if username.isEmpty || password.isEmpty {
            loginError = "Please enter both username and password."
        } else {
            let server = Server(baseURL: "http://192.168.5.4:5001")
            if server.getLoginToken(username: username, password: password) {
                loginError = nil
                isLoggedIn = true
                LoggerManager.log.info("Login successful")
                
                let token = server.token!
                if KeychainManager.shared.save(token: token, forKey: "authToken") {
                    LoggerManager.log.debug("saved authToken \(token)")
                } else {
                    print("faled to save authToken")
                }
            } else {
//                print("Login failed - \(server.errorMessage)")
                loginError = "Invalid username or password."
            }
        }
    }
    
    public func logout() {
        username = ""
        password = ""
        isLoggedIn = false
        if KeychainManager.shared.deleteToken(forKey: "authToken") {
//            print("deleted authToken")
        } else {
            print("faled to delete authToken")
        }
    }
    
    private func checkAuthenticationStatus() {
//        KeychainManager.shared.deleteToken(forKey: "authToken")
        isLoggedIn = false
        if let token = KeychainManager.shared.retrieveToken(forKey: "authToken") {
            LoggerManager.log.debug("retrieved token \(token)")
            
            // strip off "Bearer " from token string
            let index = token.index(token.startIndex, offsetBy: 7)
            let jwt = String(token[index...])
           
            if isTokenExpired(jwt) {
                LoggerManager.log.debug("Token has expired.")
            } else {
                LoggerManager.log.debug("Token is still valid.")
                isLoggedIn = true
            }
        } else {
        }
    }
    
}

extension Data {
    // Decode Base64URL string
    init?(base64URLEncoded input: String) {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64.append(contentsOf: repeatElement("=", count: paddingLength))
        }
        self.init(base64Encoded: base64)
    }
}

func parseJWT(_ jwt: String) -> [String: Any]? {
    let parts = jwt.components(separatedBy: ".")
    guard parts.count == 3 else {
        print("Invalid JWT token")
        return nil
    }
    
    let payloadPart = parts[1]
    guard let payloadData = Data(base64URLEncoded: payloadPart),
          let jsonObject = try? JSONSerialization.jsonObject(with: payloadData),
          let payload = jsonObject as? [String: Any] else {
        print("Failed to decode payload")
        return nil
    }
    
    return payload
}

func isTokenExpired(_ token: String) -> Bool {
    guard let payload = parseJWT(token) else {
        return true
    }
    
    // Check if 'exp' (expiration) claim exists and is a valid timestamp
    if let expTimestamp = payload["exp"] as? TimeInterval {
        // Compare with current date (in seconds)
        let currentTimestamp = Date().timeIntervalSince1970
        
        LoggerManager.log.debug("Token expiration date: \(date(from: expTimestamp))")
        LoggerManager.log.debug("Current date: \(date(from: currentTimestamp))")
        return currentTimestamp > expTimestamp
    } else {
        print("Expiration claim 'exp' not found")
        return true
    }
}

// create a function that takes a unix epoch timestamp and returns a human-readable date and time
func date(from timestamp: TimeInterval) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: date)
}
