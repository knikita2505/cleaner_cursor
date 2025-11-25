## ERR-005 — Video Export Fail Recovery
Требования:
- перезапустить процесс экспорта при сбое,
- если повторно ошибка → показать:
  - «We couldn’t compress this video».

---

## ERR-006 — Global Crashlytics Events
Требования:
- логировать:
  - падения PhotoKit,
  - AVAssetExportSession ошибки,
  - Paywall ошибки,
  - авторизационные ошибки Gmail.