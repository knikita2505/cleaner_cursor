import Foundation

// MARK: - Date Extensions

extension Date {
    
    // MARK: - Formatters
    
    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    // MARK: - Formatted Strings
    
    var shortFormatted: String {
        Self.shortFormatter.string(from: self)
    }
    
    var mediumFormatted: String {
        Self.mediumFormatter.string(from: self)
    }
    
    var timeFormatted: String {
        Self.timeFormatter.string(from: self)
    }
    
    var relativeFormatted: String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - Checks
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    // MARK: - Smart Format
    
    var smartFormatted: String {
        if isToday {
            return String(localized: "Today")
        } else if isYesterday {
            return String(localized: "Yesterday")
        } else if isThisWeek {
            return formatted(.dateTime.weekday(.wide))
        } else if isThisYear {
            return formatted(.dateTime.month(.abbreviated).day())
        } else {
            return shortFormatted
        }
    }
}

