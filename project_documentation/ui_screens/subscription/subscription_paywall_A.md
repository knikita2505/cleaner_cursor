# subscription_paywall_A

## Назначение
Основной экран монетизации.  
Используется в:
- онбординге,
- при попытке использовать Premium фичи,
- в Deep Clean.

Этот экран — главный драйвер подписок.

---

## Layout

### Background
- Aurora gradient (blue → purple → lilac)
- Верхняя часть чуть затемнена для лучшей читаемости текста

---

### Hero Section
- Большая иллюстрация устройства/чистоты
- Title: `Unlock Full Cleaning Power`
  - 30–32pt Bold
- Subtitle:
  - `Unlimited cleaning, smart highlights, private folder and more.`
  - 16pt, 70% opacity, max 2 строки

---

### Benefits List
3–5 иконок с текстом:

- ✓ Unlimited photo & video cleaning  
- ✓ Remove duplicates & similar  
- ✓ Secret Folder (with Face ID)  
- ✓ Video Compression  
- ✓ AI Highlights Detector  

Каждый пункт:
- иконка: gradient circle 28–34pt  
- текст: 15–16pt Medium  

---

### Pricing Cards
Три варианта:

#### 1. Weekly (most prominent)
- Card (30% taller)
- Title: `Weekly`
- Price: `$6.99`
- Subtitle: `Cancel anytime`
- Badge: `Most Popular`

#### 2. Yearly
- Title: `Yearly`
- Price: `$34.99`
- Subtitle: `Save 70%`
- Badge: `Best Value`

#### 3. Lifetime
- Title: `Lifetime`
- Price: `$29.99`
- Subtitle: `One-time purchase`
- Badge: `Limited Offer`

Пользователь может переключать план нажатием.

Выбранный план подсвечивается:
- большая тень,
- белый outline 1.5pt,
- scale 1.03.

---

### CTA Button
- Primary Button (full-width)
- Text:
  - `Start Free Trial`
  - или, если выбран Lifetime: `Continue`
- Gradient CTA
- Haptics → medium impact

---

### Footer
- Restore purchases
- Terms of Use
- Privacy Policy  
(12pt, opacity 40%)

---

## Логика
- По умолчанию выбран Weekly.
- При переключении на Yearly показывается tooltip:
  - `Save 70% compared to weekly plan`
- Lifetime → без trial.

---

## Edge Cases
- Если App Store API вернул ошибку:
  - Alert: `Unable to complete purchase. Try again later.`

---

## Связанные задачи
- PAYWALL-A-001 — UI
- PAYWALL-A-002 — выбор плана
- PAYWALL-A-003 — StoreKit purchase
