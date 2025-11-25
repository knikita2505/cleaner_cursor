# errors_and_empty_states

## Назначение
Набор стандартных экранов и состояний для обработки ошибок, отсутствия данных и отказа разрешений.

---

## 1. Errors

### No Photo Access
- Иллюстрация: замок
- Title: `No access to Photos`
- Subtitle: `Cleaner needs permission to analyze your media.`
- CTA: `Open Settings`

### No Contacts Access
То же, с другой иконкой.

### No Internet (если используется)
- Title: `No connection`
- Subtitle: `Please check your internet and try again.`
- CTA: `Retry`

### General Error
- Title: `Something went wrong`
- Subtitle: `Try again later`

---

## 2. Empty States

### No Duplicates
- Иллюстрация: чистый фотоальбом
- Title: `No duplicates found`
- Subtitle: `Your photos look clean!`
- CTA: `Back`

### No Big Files
- Title: `No large files detected`
- Subtitle: `Try adjusting filters.`

### No Spam Emails
- Title: `Inbox looks clean`

---

## 3. Loading States

### Standard Loading
- Fullscreen fade background
- Progress spinner
- Text: `Analyzing…`

### Heavy Task Loading
- Progress bar (0–100%)
- Text: `Processing 24/58 items…`

---

## Связанные задачи
- ERROR-001 — общие ошибки
- ERROR-002 — empty states
- ERROR-003 — loaders
