# UI Design Specification — iOS Cleaner App

## 1. Visual Philosophy (Core Style)
Основная концепция UI — это сочетание:
- **Premium Aurora Gradient** для онбординга и paywall
- **Modern iOS Dark Grey** для рабочих экранов
- **Blue/Purple accents** для CTA и ключевых действий

UI не должен выглядеть как набор разных стилей — цвета, формы и типографика строго унифицированы.  
Основной тон: премиальный, уверенный, современный, "дорогой", но не перегруженный.

### Короткое описание стиля:
- Фон: тёмный, глубокий, мягкий.
- Акценты: яркие, но не кислотные.
- Формы: плавные, округлённые.
- Контент: крупный, воздушный, легко сканируемый.
- Главные кнопки: большие, заметные, премиальные.
- Визуальная метафора: «чистота и порядок внутри устройства».

---

## 2. Color Palette

### **Основной фон**
- `#0D0F16` — глубокий тёмный синий
- `#111214` — графитовый (для рабочих экранов)

### **Акцентные цвета**
- Основной синий: `#3B5BFF`
- Фиолетовый: `#7A4DFB`
- Сиреневый светлый: `#A88CFF`
- Голубое свечение: `#7FB9FF`

### **Градиенты (ключевые)**
#### CTA Gradient (primary)
- `#3B5BFF` → `#7A4DFB`

#### Aurora Gradient (для онбординга и paywalls)
- `#2F3DAF` → `#6B3BDB` → `#8B5CFF`

### **Текст**
- Основной: `#FFFFFF` (bold headers)
- Вторичный: `#E6E8ED` (описания)
- Третичный: `#AEB4BE` (системные тексты)

### **Успех / Предупреждение**
- Success: `#41D3B3`
- Warning: `#FFB84D`
- Error (редко используется): `#FF4D4D`

---

## 3. Typography

### Базовый шрифт:
- **SF Pro** (Display / Text)

### Иерархия:
#### Заголовки:
- Title XL: 32pt Bold  
- Title L: 28pt Bold  
- Title M: 24pt Semibold  

#### Подзаголовки:
- Subtitle L: 18pt Medium  
- Subtitle M: 16pt Medium  

#### Текст:
- Body L: 16pt Regular  
- Body M: 14pt Regular  
- Caption: 12pt Regular, 60% opacity  

### Принципы:
- Заголовки всегда крупные, в верхней части экрана.
- Интерлиньяж широкий (1.2–1.3).
- Текст максимум из 1–2 строк.

---

## 4. Layout & Spacing

### Основная сетка:
- Внешние отступы: **20–24pt**
- Внутренние отступы в контейнерах: **16–20pt**
- Между блоками: **16pt**
- Между иконкой и текстом: **12pt**

### Скругления:
- Карточки: **20pt**
- Кнопки: **16–20pt**
- Модалки: **32pt**

### Тени:
Используем лёгкие мягкие тени, почти незаметные:
- Shadow: black 30% opacity, blur 8–12

---

## 5. Core Components

## 5.1. Buttons

### **Primary Button**
- Full width
- Height: 56pt
- Corner radius: 16pt
- Background: CTA Gradient
- Text: white, 18pt, Medium
- Shadow: gradient-shadow soft

### **Secondary Button**
- Border: `rgba(255,255,255,0.2)`  
- Transparent fill  
- Corner radius: 16pt  
- Text: 16pt Medium  

### **Ghost / Minimal Button**
- Без фона  
- Text: 16pt, opacity 70%  
- Используется в настройках и нижних блоках paywall 

---

## 5.2. Cards

### **Primary Card**
- Background: `#111214`
- Radius: 20pt
- Padding: 20pt
- Shadow: soft
- Контент: иконка + заголовок + подзаголовок + CTA indicator

### **List Card (для Scanner / Photo categories)**
- Row-style
- Height: 72–80pt  
- Icon left (36–44pt)  
- Text stack (title + counter)  
- Chevron right  
- Background: `#121317`

---

## 5.3. Progress Bars
- Height: 8pt  
- Radius: full  
- Background inactive: `rgba(255,255,255,0.1)`  
- Active bar gradient: `#FF8D4D` → `#FFD36B`  
(для storage indicators)

---

## 5.4. Icons
- Стиль: **SF Symbols** или кастом в SF-стилистике  
- Цвет: акцентный синий/фиолетовый  
- Размеры: 24pt / 32pt  

---

## 5.5. Modals

### **Standard Modal**
- Background: `#0F1116`
- Radius: 32pt
- Title: 24pt Bold
- Subtitle: 16pt Regular
- Primary button → CTA gradient
- Secondary button → border style

### **System-like Permission Screens**
- Fullscreen
- Большая иконка permission (80pt)
- Title: 28pt Bold
- Description: светлый текст 16pt
- CTA: Primary button

---

## 6. Onboarding Design

### Общие правила:
- 3–4 экрана
- Aurora gradient background
- Большие rounded cards
- Иллюстрации в синих/фиолетовых тонах
- Прогресс-бар сверху (3–4 точки)
- CTA всегда внизу (Primary)

### Структура слайда:
1. Иллюстрация 180–220pt  
2. Заголовок (28–32pt Bold)  
3. Описание (16pt, 70% opacity)  
4. Хинты свайпом или indicator  
5. CTA  

---

## 7. Paywall Design

### Основной стиль:
- Aurora gradient (снизу затемнение)
- Большой визуальный блок:  
  - Storage usage  
  - Количество мусора  
  - Иконки категорий  

### Цены:
- Weekly 6.99  
- Yearly 34.99 (с выгодой -70%)  
- Lifetime 29.99  
- Бейджи “Best Value”, “Limited Offer”

### Принципы:
- Огромная CTA-кнопка  
- Минимум второстепенного текста  
- Снизу: Terms + Privacy (12pt, opacity 40%)  

---

## 8. Secret Folder UI

### Основной цвет:
- Dark grey background  
- Лёгкие фиолетовые акценты  

### Элементы:
- Grid preview 3x  
- Hidden mode  
- Локальный пароль  
- Биометрия (Touch ID / Face ID)  

---

## 9. Charging Animations Style
- Тёмный фон  
- Анимированный градиент  
- Частицы или светящиеся полосы  
- Минимальная нагрузка на GPU  
- Не должно выглядеть как системная функция iOS  

---

## 10. Visual Interaction Rules

### Hover / Tap Feedback
- Уменьшение элемента на 3–5%  
- Лёгкая подсветка CTA  
- Ripple-light эффект (очень слабый)

### Transitions
- Smooth slide  
- Fade-in  
- Scale-in для карточек  

### List Scrolling
- стандартизированная bounce-physics  

---

## 11. Animation Guidelines
- Duration: 0.25–0.35s  
- Easing: `.easeOut` / `.easeInOut`  
- Не использовать резкие spring-анимации  
- Плавность как в системных приложениях Apple  

---

## 12. Illustration Style

### Основные принципы:
- Плоские формы 2D  
- Soft shading  
- Цвет: оттенки синего, фиолетового и белого  
- Лёгкие градиенты  
- Иллюстрации не должны быть слишком мультяшными  

Используется для:
- Onboarding  
- Paywall  
- Empty states  

---

## 13. Light/Dark Mode
На старте применяется **только Dark Mode**.  
Light Mode можно добавить в версии 1.2+.

---

## 14. Objectives for AI IDE
Этот документ служит руководством для:
- генерации UI-компонентов  
- создания общей темы (colors, styles)  
- построения экранов  
- использования единых кнопок/карт  
- рендеринга онбординга и paywall  
- формирования визуально цельного приложения  

Искусственный интеллект должен использовать все описанные значения как **обязательные стандарты дизайна**.