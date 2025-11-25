# contacts_cleaner

## Назначение
Экран для очистки контактов:
- объединение дубликатов,
- удаление пустых контактов,
- исправление неправильных форматов,
- упрощение записной книги.

Этот экран должен давать ощущение порядка и «моментальной пользы» от приложения.

---

## Основной сценарий
1. Пользователь открывает Contacts Cleaner.
2. Приложение сканирует адресную книгу.
3. Выводятся категории проблем: дубликаты, пустые записи, неправильный формат.
4. Пользователь выбирает, что исправить.
5. Приложение применяет исправления автоматически.

---

## Layout

### Header
- Title: **Contacts Cleaner**
- Subtitle: `Fix duplicates, empty entries and formatting issues.`

### Summary Card (Primary Card)
- Заголовок: `We found 34 issues`
- Подзаголовок:  
  - `12 duplicate contacts`  
  - `18 without phone/email`  
  - `4 with wrong formatting`
- Маленький badge: `Safe to clean`

### Issue Categories List
Это список карточек, каждая отвечает за тип проблемы.

Каждая карточка (List Card):
- Иконка слева:
  - Дубликаты → `person.2.fill`
  - Пустые контакты → `person.crop.circle.badge.xmark`
  - Неправильный формат → `textformat.alt`
- Текст:
  - Primary: `Duplicate Contacts`
  - Secondary: `12 duplicates • Recommended fix`
- Справа: Chevron `>`

---

## Детальные экраны проблем

### 1. Duplicate Contacts Screen (Sub-view)
#### Layout:
- Title: `Duplicate Contacts`
- Subtitle: `We grouped duplicates by name or number.`

Каждая группа:
- Главный контакт — карточка со всей информацией.
- Под ним список "child" контактов:
  - Name
  - Phone/email
  - Badge: `Will be merged`
  - Checkbox (always preselected)
- CTA: **Merge All (12)**

#### Логика:
- Объединение выполняется через CNMutableContact + CNSaveRequest.
- Создаётся одна объединённая запись.
- Дубликаты удаляются.

---

### 2. Empty Contacts Screen
#### Layout:
- Title: `Empty Contacts`
- Subtitle: `Contacts without phone or email.`

Каждый элемент:
- Имя (или “Unnamed contact”)
- Secondary: “No phone • No email”
- Checkbox справа

CTA: **Delete selected**

---

### 3. Formatting Issues Screen
#### Layout:
- Title: `Formatting Issues`
- Subtitle: `Normalize phone number formats.`

Каждый элемент:
- Имя человека
- Old → New format:
  - `+1 (202) 555-0144` → `+12025550144`
- Switch: “Apply fix”

CTA: **Fix All**

---

## Bottom Summary Bar (общий компонент)
- Слева: `Selected: X`
- Справа: Primary Button (действие зависит от экрана)

---

## Внешний вид
- Фон: `#111214`
- Карточки: `#121317`, radius 16–20pt
- Иконки: синий/фиолетовый акцент
- Checkbox: полный gradient fill

---

## Логика
- Приложение не требует никакого сервера — ContactService работает полностью оффлайн.
- Все действия безопасны:
  - Перед удалением или merge выводится модалка подтверждения.
- После операции показывается snackbar:
  - `12 contacts merged successfully`

---

## Edge Cases
- Нет проблем:
  - Empty State: иллюстрация + текст:  
    `Your contacts look perfect!`

---

## Связанные задачи
- CONTACTS-001 — поиск дубликатов
- CONTACTS-002 — поиск пустых контактов
- CONTACTS-003 — исправление форматов
- CONTACTS-004 — массовое применение изменений
