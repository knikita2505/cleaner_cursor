# Описание бесплатного и платного функционала для Apple Review

## Для заполнения в App Store Connect

### Поле: "Subscription Description" (Review Notes для In-App Purchases)

---

## Subscription Group Name
**MagicSwipe Premium**

---

## Subscription Plans

### Plan 1: Weekly Access
- **Product ID:** `magicswipe.premium.week1`
- **Duration:** 1 week (auto-renewable)
- **Free Trial:** 3-day free trial (for eligible users)
- **Description:** Weekly subscription to MagicSwipe Premium with unlimited photo and contact cleaning, secret storage vault, and cleanup analytics.

### Plan 2: Yearly Access
- **Product ID:** `magicswipe.premium.year1`
- **Duration:** 1 year (auto-renewable)
- **Free Trial:** None
- **Description:** Annual subscription to MagicSwipe Premium with unlimited photo and contact cleaning, secret storage vault, and cleanup analytics. Best value option.

---

## Free vs Premium Feature Comparison

### FREE (без подписки)

| Feature | Availability | Limit |
|---------|-------------|-------|
| **Photo Scanner** | Full access | View results, up to 50 deletions/day |
| Scan for duplicate photos | ✅ | — |
| Scan for similar photos | ✅ | — |
| Scan for screenshots | ✅ | — |
| Scan for Live Photos | ✅ | — |
| Scan for burst photos | ✅ | — |
| Scan for large files | ✅ | — |
| Delete photos | ✅ | 50 items per day |
| **Video Scanner** | Full access | Up to 50 deletions/day |
| View all videos | ✅ | — |
| View large videos (>100MB) | ✅ | — |
| View short videos (<10s) | ✅ | — |
| Delete videos | ✅ | 50 items per day |
| **Swipe Clean** | Full access | Up to 50 deletions/day |
| Browse photos by month | ✅ | — |
| Swipe to sort (keep/delete) | ✅ | — |
| Batch delete swiped photos | ✅ | 50 items per day |
| **Device Health** | Full access | No limit |
| Overall health score | ✅ | — |
| Battery monitoring | ✅ | — |
| Storage analysis | ✅ | — |
| Performance & temperature | ✅ | — |
| Battery tips | ✅ | — |
| **Onboarding** | ✅ | — |
| **Push Notifications** | ✅ | — |

**Daily Limit:** Free users can delete/clean up to **50 items per day** across all categories (photos, videos, contacts). The limit resets every 24 hours. Scanning and viewing results is always unlimited.

---

### PREMIUM (с подпиской)

| Feature | Description |
|---------|-------------|
| **Unlimited Cleaning** | Remove unlimited photos, videos, and contacts per day with no daily cap |
| **Contacts Cleaner** | Full access to contact management: find duplicates, merge similar contacts, clean empty contacts, backup & restore |
| **Secret Storage Vault** | Private vault protected with PIN code and Face ID/Touch ID for hiding sensitive photos, videos, and contacts |
| **Cleanup Analytics** | Detailed cleaning statistics with weekly bar charts, monthly pie charts, and personalized cleaning recommendations |
| **Ad-Free Experience** | Completely ad-free experience throughout the app |

---

## Review Notes (для App Store Connect)

### Вставить в поле "Review Notes" при подаче

```
SUBSCRIPTION INFORMATION:

MagicSwipe offers two auto-renewable subscription options:

1. Weekly Premium ($X.XX/week) — includes 3-day free trial for first-time subscribers
2. Yearly Premium ($XX.XX/year) — best value, no trial

FREE FUNCTIONALITY:
- Scan device for duplicate photos, similar photos, screenshots, Live Photos, burst photos, and large files — unlimited scanning
- View all scan results with counts and file sizes
- Delete up to 50 items per day (photos, videos)
- Swipe Clean: browse photos by month and swipe to sort — delete up to 50/day
- Device Health: battery monitoring, storage analysis, performance score, temperature monitoring, battery tips
- Push notification reminders

PREMIUM FUNCTIONALITY (requires subscription):
- Unlimited daily cleaning (no 50-item cap)
- Contacts Cleaner: find duplicate contacts, merge similar names, remove empty contacts, backup & restore
- Secret Storage: PIN + Face ID/Touch ID protected vault for private photos, videos, and contacts
- Cleanup Analytics: weekly/monthly charts, cleaning statistics, personalized recommendations
- Ad-free experience

The paywall is shown:
1. After onboarding completion (can be dismissed with X button)
2. When user reaches the 50-item daily cleaning limit
3. When user tries to access premium-only features (contacts, secret space, analytics)

All paywalls can be dismissed. The app is fully functional for free users with the 50-item daily limit.

Restore Purchases is available on all paywall screens.

Terms of Use: https://magicswipe.app/terms.html
Privacy Policy: https://magicswipe.app/privacy.html

TEST ACCOUNT: [Предоставить sandbox test account если нужно]
```

---

## Subscription Disclaimer (обязательный текст на Paywall)

### Вставить на экран Paywall (мелким шрифтом под CTA)

#### Полная версия (рекомендуется):
```
Payment will be charged to your Apple ID account at the confirmation of purchase. 
The subscription automatically renews unless it is canceled at least 24 hours before 
the end of the current period. Your account will be charged for renewal within 24 hours 
prior to the end of the current period. You can manage and cancel your subscriptions 
by going to your account settings on the App Store after purchase.
```

#### Короткая версия (минимум):
```
Auto-renewable subscription. Cancel anytime in App Store Settings. 
Payment charged to Apple ID at confirmation.
```

#### Для trial:
```
After the 3-day free trial, you will be charged [price]/week. 
Cancel anytime before the trial ends to avoid being charged.
Subscription automatically renews unless canceled at least 24 hours 
before the end of the current period.
```

---

## Metadata для App Store Connect

### Subscription Localization (English)

**Display Name:** MagicSwipe Premium

**Description (для каждого плана):**

Weekly:
```
Unlock unlimited cleaning, contacts management, secret vault, and analytics. 
Clean unlimited photos, videos and contacts daily. Subscription auto-renews weekly.
```

Yearly:
```
Unlock unlimited cleaning, contacts management, secret vault, and analytics. 
Best value — save over 80% compared to weekly plan. Subscription auto-renews annually.
```

---

## Privacy Nutrition Labels (App Store Connect)

### Данные, которые нужно указать:

| Data Type | Collection | Purpose | Linked to User |
|-----------|-----------|---------|----------------|
| **Photos** | Yes | App Functionality | No |
| **Contacts** | Yes | App Functionality | No |
| **Device ID (IDFV)** | Yes | Analytics, Advertising | No |
| **Advertising ID (IDFA)** | Yes (with ATT) | Advertising, Attribution | No |
| **Purchase History** | Yes | App Functionality | Yes |
| **Usage Data** | Yes | Analytics | No |
| **Diagnostics** | Yes | App Functionality | No |

### Data NOT Collected:
- Name, Email, Phone (не отправляются на серверы)
- Location
- Health & Fitness
- Financial Data
- Browsing History
- Search History

**Важно:** Secret Space данные (фото, контакты) хранятся ТОЛЬКО на устройстве и НЕ передаются на серверы.

---

## Checklist перед подачей

- [ ] Terms of Use доступен по URL
- [ ] Privacy Policy доступен по URL
- [ ] Privacy Policy описывает: фото, контакты, IDFA, IDFV, AppsFlyer, Apphud
- [ ] Subscription disclaimer добавлен на все paywall-экраны
- [ ] Sandbox test account создан
- [ ] App Store Connect: все IAP продукты созданы
- [ ] App Store Connect: subscription descriptions заполнены
- [ ] App Store Connect: Privacy Nutrition Labels заполнены
- [ ] App Store Connect: Review Notes заполнены
- [ ] Screenshots подготовлены (5.5", 6.7", iPad если нужно)
- [ ] Все SKAdNetworkItems добавлены в Info.plist (для AppsFlyer)
