## LOC-001 — Multi-language Support (EN/JP/PT)
Требования:
- загрузка перевода для всех крупных текстовых экранов:
  - онбординг,
  - paywall,
  - tips,
  - battery,
  - errors.
- динамическая смена языка в UI.
- локаль сохраняется в UserDefaults.
- fallback → EN.
- Логирование:
  - `lang_changed`.

---

## LOC-002 — Auto-detect locale on first launch
Требования:
- определить язык устройства → автоматически выставить основной язык UI.