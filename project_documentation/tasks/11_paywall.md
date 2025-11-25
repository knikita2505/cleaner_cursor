## PAYWALL-001 — Paywall A
- Основной paywall, full-gradient.
- Weekly/Yearly/Lifetime.
- Trial для Weekly и Yearly.
- Логировать:
  - `paywall_view`
  - `paywall_plan_select`
  - `paywall_purchase_start`
  - `paywall_purchase_success`
  - `paywall_purchase_fail`

---

## PAYWALL-002 — Paywall B (A/B)
- Темный стиль.
- Упор на storage.
- Те же планы.

---

## PAYWALL-003 — Free limit enforcement
- Пользователь может удалить max 50 файлов в день.
- При достижении → экран free_limit.
- Логировать:
  - `limit_reached`