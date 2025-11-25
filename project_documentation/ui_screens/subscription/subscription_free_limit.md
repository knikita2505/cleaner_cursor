# subscription_free_limit

## Назначение
Экран показывается, когда пользователь достиг дневного лимита (например, очистил 50 файлов).

---

## Layout

### Header
- Иконка warning (оранжевая)
- Title: `Daily limit reached`
- Subtitle: `You cleaned 50 items today on the free plan.`

### Summary Card
- Заголовок: `Unlock unlimited cleaning`
- Подзаголовок: `Remove duplicates, similar photos and more.`

### CTA
Primary Button:
- `Upgrade to Premium`

Secondary Button:
- `Maybe later`

### Footer
- `Limits reset daily`

---

## Логика
- Переход на Paywall A или B (через конфиг).

---

## Связанные задачи
- PAYWALL-LIMIT-001 — лимиты free
- PAYWALL-LIMIT-002 — показ экрана
