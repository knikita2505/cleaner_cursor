# Project Description — iOS Cleaner App

## 1. Overview
iOS Cleaner — это мобильное приложение для очистки iPhone, ориентированное на массовую аудиторию из США, Японии и Бразилии.  
Приложение сочетает в себе высокую скорость работы, простой UX/UI, современный визуальный стиль и расширенный набор утилит: очистка фото/видео, управление контактами, компрессия видео, анализ батареи, секретный альбом, очистка email-спама и уникальная фича Smart Highlights Detector.

Проект создаётся полностью с помощью AI IDE (Google Antigravity / Cursor), основной UI-фреймворк — **SwiftUI**, архитектура — **MVVM + Services**, аналитика — **Firebase**.

---

## 2. Positioning & Value Proposition
Приложение позиционируется как:
- **Premium Cleaner Utility** с современным тёмным UI.
- Удобный и понятный инструмент для освобождения памяти.
- Продукт для массового трафика (TikTok Ads, UA постинг, нутра/серые воронки).
- Легковесное приложение, быстро выполняющее основные задачи.

### Ключевые преимущества:
- Высокое качество UX/UI (микс Premium Aurora Gradient + Modern iOS Dark).
- Уникальные фичи (Swipe-to-clean, Smart Highlights Detector, Video Compression).
- Сильные paywall-экраны с A/B тестами.
- Лёгкая архитектура и простой код (подходит для генерации ИИ).
- Friendly для App Store Review (без токсичных серых функций).

---

## 3. Target Audience
1. **США / Japan / Brazil** — активные пользователи iPhone.
2. Пользователи, у которых постоянно заканчивается память.
3. Люди, которые часто снимают фото/видео.
4. Владельцы дешёвых планов iCloud (50GB).
5. Неопытные пользователи, которым нужна простая очистка устройства.

---

## 4. Key Features (MVP Scope)

### 📸 Фото / Видео
- Duplicate Photos Detection  
- Duplicate Videos Detection  
- Similar Photos  
- Screenshots Cleaner  
- Live Photos Cleaner  
- Burst Mode Cleaner  
- Big Files  
- Swipe-to-Clean (удаление свайпами)  
- Video Compression (архивация больших файлов)  
- **Smart Highlights Detector (AI-lite)** — выбор лучших фото по эвристикам

### 📞 Контакты
- Merge duplicate contacts  
- Remove empty contacts  
- Normalize phone formats  

### 📬 Почта
- Spam cleaner  
- Mass unsubscribe  
- Анализ отправителя  

### 🔋 Батарея
- Battery monitor  
- Battery usage tips  
- **Pseudo charging animations**

### 🔐 Secret Folder
- Secure vault for photos/videos  
- Passcode lock  
- Biometric unlock  

### 📦 Storage Overview
- Storage categories  
- Общий анализ заполненности памяти  
- Виджет  

### 🔔 Push Notifications
- Low storage alert  
- Duplicates found  
- Trial ending  
- Scan results  
- Reminder cleanups  

### 💰 Monetization
- Weekly plan: **$6.99**  
- Yearly plan: **$34.99**  
- Lifetime promo: **$29.99**  
- А/B тестирование paywalls  
- Ограниченный free режим: до **50 файлов** очистки в день  

---

## 5. Supported Languages
- English  
- Japanese  
- Portuguese (BR)  

---

## 6. Tech Stack

### Language & Frameworks
- **Swift 5+**
- **SwiftUI** (основной UI стек)
- **UIKit** (опционально, если потребуется)
- **Combine / ObservableObject / async/await**
- **PhotoKit**
- **Contacts Framework**
- **StoreKit 2**
- **UserNotifications**
- **LocalAuthentication**

### Services
- Firebase Analytics  
- Firebase Crashlytics  
- Firebase Firestore (логи + feature flags)  

---

## 7. Architecture

### Архитектурный паттерн
- **MVVM** для экранов  
- **Service Layer**:
  - PhotoService  
  - VideoService  
  - ContactsService  
  - MailService  
  - StorageService  
  - BatteryService  
  - SecretFolderService  
  - SubscriptionService (StoreKit 2)  
  - LogService (Firebase)  

### Data Flow
- UI → ViewModel → Service → Apple API (PhotoKit/Contacts)
- UI → ViewModel → StoreKit 2
- UI → ViewModel → Firestore (логирование)


### Локальные данные
- UserDefaults (настройки)  
- Secure Enclave (Secret Folder)  
- Lightweight caches (thumbnails, previews)  

---

## 8. App Structure (High-Level)

### Onboarding
1. Welcome  
2. Photo cleaning intro  
3. Video & storage intro  
4. Battery/Secret folder intro  
5. Paywall  

### Main App
- Dashboard  
- Photo Cleaner  
- Video Cleaner  
- Contacts Cleaner  
- Email Cleaner  
- Secret Folder  
- Storage Breakdown  
- Settings  

---

## 9. App Store Compliance Notes
- Не использовать термин “RAM cleaning”, “boost”, “instant speed”.  
- Только реальный доступ к фото/видео.  
- Псевдо-анимации должны называться “Creative Charging Screens”.  
- Никаких system-like popups.  
- Secret Folder должен использовать локальное шифрование (простой SecureEnclave).  

---

## 10. Roadmap
### Version 1.0
- Базовый функционал фото/видео  
- Contacts cleaner  
- Mail spam cleaner  
- Battery tips  
- Secret folder  
- Onboarding + Paywalls  
- StoreKit интеграция  
- Firebase  
- Pushes  

### Version 1.1
- Улучшенная система Smart Highlights  
- Swipe-to-clean improvements  
- Улучшение поиска похожих фото  

### Version 1.2
- Extended video compression  
- Полное обновление UI компонентов  

---

## 11. Goals for AI IDE
Этот документ служит основным контекстом для:
- генерации структуры проекта  
- создания экранов  
- генерации сервисов  
- построения навигации  
- создания подписочной логики  
- интеграции Firebase  
- генерации UI по стилю из ui_design.md  
- согласования фич с tasks.md  
