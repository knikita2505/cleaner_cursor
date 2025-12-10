# [SCREEN] email_cleaner_connect

## Назначение
Экран подключения почтового аккаунта (например, Gmail) для очистки промо-и спам-писем.

---

## UI

- Заголовок: `Email Cleaner`.
- Описание: `Connect your email to find and remove newsletters and spam in bulk.`
- Большая кнопка `Sign in with Google`.
- Мелкий текст: `Your login is secured by Google. We don’t store your password.`

---

## Логика

- Нажатие: OAuth-флоу → получаем токен с минимальными правами.
- В случае успеха → `email_cleaner_inbox_cleanup`.
- В случае отказа — показываем баннер и оставляем возможность повторить.

---

## Аналитика
- `email_connect_open`
- `email_connect_success`
- `email_connect_fail`
