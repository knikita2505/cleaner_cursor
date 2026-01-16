import Foundation
import UserNotifications

// MARK: - Notification Service
/// Сервис для управления локальными push-уведомлениями

@MainActor
final class NotificationService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Constants
    
    private let notificationsEnabledKey = "notifications_enabled"
    private let planningDays = 14
    private let minimumDaysThreshold = 5
    private let morningHour = 9
    private let morningMinute = 45
    private let eveningHour = 17
    private let eveningMinute = 45
    private let notificationIdentifierPrefix = "cleaner_notification_"
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: notificationsEnabledKey)
        }
    }
    
    // MARK: - Notification Content Variants
    
    private let notificationVariants: [(title: String, body: String)] = [
        ("Too Many Duplicates? 🧹", "Remove duplicate photos and videos with one tap."),
        ("🧼 Refresh Your Gallery Now", "Time to refresh your gallery? We're ready – just tap!"),
        ("🚀 Free Up iPhone Storage Fast", "Your iPhone will thank you – remove the clutter in seconds!"),
        ("Compress Videos, Keep Quality 🎥", "Save space without losing a pixel."),
        ("Let's Declutter! 💨", "Don't let junk slow you down – clean it out now!"),
        ("Instant Performance Boost 🔋", "Free space, run smoother, feel the speed!"),
        ("Your Storage Is Waiting 📱", "Hidden clutter may be taking space — clean it in seconds."),
        ("Smart Cleanup Time ✨", "Duplicates and similar files won't remove themselves."),
        ("More Space, Less Noise 🧠", "Keep only what matters — delete the rest easily."),
        ("Quick Scan, Big Win ⚡", "One tap can free hundreds of megabytes."),
        ("Keep Your iPhone Light 🪶", "Remove unnecessary photos and videos effortlessly."),
        ("Clean Today, Relax Tomorrow 😌", "A quick cleanup keeps your phone running smoothly.")
    ]
    
    // MARK: - Init
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }
    
    // MARK: - Public Methods
    
    /// Запрос разрешения на уведомления
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Проверка статуса разрешения
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Включить уведомления
    func enableNotifications() async {
        let status = await checkAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            let granted = await requestAuthorization()
            if granted {
                isEnabled = true
                await scheduleNotifications()
            }
        case .authorized, .provisional, .ephemeral:
            isEnabled = true
            await scheduleNotifications()
        case .denied:
            // Пользователь запретил уведомления в настройках iOS
            isEnabled = false
        @unknown default:
            isEnabled = false
        }
    }
    
    /// Выключить уведомления
    func disableNotifications() {
        isEnabled = false
        removeAllScheduledNotifications()
    }
    
    /// Проверка и поддержка расписания при запуске приложения
    func maintainScheduleIfNeeded() async {
        guard isEnabled else { return }
        
        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else {
            // Если разрешение отозвано, выключаем toggle
            isEnabled = false
            return
        }
        
        let remainingDays = await getRemainingScheduledDays()
        
        if remainingDays < minimumDaysThreshold {
            print("📅 Remaining scheduled days: \(remainingDays). Rescheduling...")
            await scheduleNotifications()
        } else {
            print("📅 Remaining scheduled days: \(remainingDays). No action needed.")
        }
    }
    
    // MARK: - Private Methods
    
    /// Планирование уведомлений на 14 дней
    private func scheduleNotifications() async {
        // Удаляем старые уведомления
        removeAllScheduledNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<planningDays {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Утреннее уведомление (09:45)
            await scheduleNotification(
                for: targetDate,
                hour: morningHour,
                minute: morningMinute,
                identifier: "\(notificationIdentifierPrefix)morning_\(dayOffset)"
            )
            
            // Вечернее уведомление (17:45)
            await scheduleNotification(
                for: targetDate,
                hour: eveningHour,
                minute: eveningMinute,
                identifier: "\(notificationIdentifierPrefix)evening_\(dayOffset)"
            )
        }
        
        print("✅ Scheduled \(planningDays * 2) notifications for the next \(planningDays) days")
    }
    
    /// Планирование одного уведомления
    private func scheduleNotification(for date: Date, hour: Int, minute: Int, identifier: String) async {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // Создаём дату с нужным временем
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard let scheduledDate = calendar.date(from: components) else { return }
        
        // Пропускаем, если время уже прошло
        if scheduledDate <= Date() { return }
        
        // Выбираем случайный вариант контента
        let variant = notificationVariants.randomElement() ?? notificationVariants[0]
        
        // Создаём контент
        let content = UNMutableNotificationContent()
        content.title = variant.title
        content.body = variant.body
        content.sound = .default
        
        // Создаём триггер
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Создаём запрос
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }
    
    /// Удаление всех запланированных уведомлений
    private func removeAllScheduledNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        print("🗑️ Removed all pending notifications")
    }
    
    /// Получение количества оставшихся дней с запланированными уведомлениями
    private func getRemainingScheduledDays() async -> Int {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        // Фильтруем только наши уведомления
        let ourRequests = pendingRequests.filter { $0.identifier.hasPrefix(notificationIdentifierPrefix) }
        
        guard !ourRequests.isEmpty else { return 0 }
        
        // Находим самую позднюю дату
        let calendar = Calendar.current
        var latestDate: Date = Date()
        
        for request in ourRequests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let triggerDate = trigger.nextTriggerDate() {
                if triggerDate > latestDate {
                    latestDate = triggerDate
                }
            }
        }
        
        // Вычисляем количество дней до самой поздней даты
        let days = calendar.dateComponents([.day], from: Date(), to: latestDate).day ?? 0
        return max(0, days)
    }
}

