import Foundation

// MARK: - String Extensions

extension String {
    
    // MARK: - Validation
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^[0-9+]{10,15}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }
    
    // MARK: - Transformations
    
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var normalized: String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    // MARK: - Phone Number Formatting
    
    var formattedPhoneNumber: String {
        let digits = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.count == 10 {
            let areaCode = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let last = digits.dropFirst(6)
            return "(\(areaCode)) \(middle)-\(last)"
        } else if digits.count == 11, digits.first == "1" {
            let withoutCountryCode = String(digits.dropFirst())
            let areaCode = withoutCountryCode.prefix(3)
            let middle = withoutCountryCode.dropFirst(3).prefix(3)
            let last = withoutCountryCode.dropFirst(6)
            return "+1 (\(areaCode)) \(middle)-\(last)"
        }
        
        return self
    }
    
    // MARK: - Truncation
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    // MARK: - Localization Helpers
    
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Optional String Extensions

extension Optional where Wrapped == String {
    
    var orEmpty: String {
        self ?? ""
    }
    
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

