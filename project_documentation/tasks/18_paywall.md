## PAYWALL-004 — A/B Switching Logic
Требования:
- Выбор Paywall A или Paywall B на основе:
  - случайного процента,
  - или конфигурации (feature flag).
- Хранение версии, которую пользователь видел в последний раз.
- Логирование:
  - `paywall_variant_a`
  - `paywall_variant_b`

---

## PAYWALL-005 — Paywall Engagement Analytics
Назначение: собирает данные поведения пользователя на пейволле.

Требования:
- метрики:
  - время нахождения,
  - скроллинг,
  - попытки закрыть,
  - взаимодействие с планами.
- Логирование:
  - `paywall_time_spent`
  - `paywall_scrolled`
  - `paywall_close_attempt`

---

## PAYWALL-006 — Psychological UX Features
(Огромный плюс для серого трафика)

Требования:
- delayed CTA:
  - кнопка «Start Trial» появляется через 0.9–1.2 сек.
- micro-animations (пульсация выгоды)
- highlight “Best Value” через 2 секунды
- подсветка Yearly → «70% OFF» мигает 1 раз
- Логирование:
  - `paywall_ux_prompt_shown`