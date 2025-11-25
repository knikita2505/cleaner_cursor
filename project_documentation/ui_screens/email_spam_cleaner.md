# email_spam_cleaner

## Назначение
Экран для очистки почтового спама и массового отписывания.  
Задача — показать пользователю, сколько «мусорных» писем можно очистить и как это освобождает память/уменьшает засоренность почты.

---

## Основной сценарий
1. Пользователь открывает Email Cleaner.
2. Приложение предлагает войти через Gmail (OAuth).
3. После входа приложение анализирует последние ~2000 писем.
4. Показывает список отправителей, которые считаются спамерами.
5. Пользователь удаляет письма одним нажатием или отписывается.

---

## Layout

### Header
- Title: **Email Cleaner**
- Subtitle: `Remove spam and unsubscribe from unwanted mailing lists.`

### Summary Card
Primary Card:
- Заголовок: `We found 393 spam emails`
- Подзаголовок: `From 14 suspicious senders`
- Badge: `Recommended cleanup`

CTA:  
- `Connect Gmail` — если пользователь ещё не авторизован  
- либо `Rescan inbox` — если авторизация уже была

---

## Gmail Login State

### 1. Before Login
- Большая кнопка:
  - Google logo + `Sign in with Google`
- Subtitle:
  - `We use secure Gmail OAuth. We never store your password.`

### 2. After Login — Senders List
Появляется список подозрительных отправителей:

Каждый элемент (Sender Row):
- Иконка/аватар отправителя (круглая)
- Primary: имя или email (`noreply@randomoffers.com`)
- Secondary: `142 emails • last 3 months`
- Action buttons:
  - `Delete All` (красная кнопка-контур)
  - `Unsubscribe` (secondary button)

Доп. бейджи:
- `High volume`
- `Promotional`
- `Spam`

---

## Mass Action Bar (если выбрано несколько отправителей)
- Left: `Selected: 3 senders`
- Right: Primary Button: `Delete 392 emails`

---

## Bottom CTA (фиксация)
Если есть ненужные письма:
- Primary Button: **Clean All Spam**
- Secondary: `Keep all`

---

## Внешний вид
- Фон: тёмный (#111214)
- Карточки отправителей: тёмно-серые (#121317)
- Кнопки:
  - Delete All → красная обводка
  - Unsubscribe → прозрачная с белой обводкой
  - Clean All → основной градиент CTA

---

## Логика

### Авторизация
- Через Google OAuth (GoogleSignIn SDK)

### Анализ почты (упрощённая схема)
- Загрузка metadata последних 2000 писем
- Группировка по отправителям
- Подсчёт количества писем
- Оценка "спамности" по:
  - ключевым словам,
  - отсутствию имени отправителя,
  - количеству рассылок,
  - частоте писем,
  - одинаковым темам.

### Действия
#### Delete All
- Удаляет все письма конкретного отправителя.
- Прогресс: `Deleting 142 emails...`

#### Unsubscribe
- Если письмо содержит ссылку unsubscribe:
  - Открывается встроенный WebView
  - Пользователь подтверждает отписку.

---

## Edge Cases
- Нет доступа к Gmail → используем передлогин экран
- Нет спама → показываем:
  - Иллюстрация
  - Text: “Your inbox looks clean!”
  - CTA: `Back`

---

## Связанные задачи
- EMAIL-001 — Gmail OAuth
- EMAIL-002 — анализ писем
- EMAIL-003 — массовое удаление
- EMAIL-004 — отписка от рассылок
