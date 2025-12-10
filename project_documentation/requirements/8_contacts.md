# Экран: Contacts Cleaner

## Назначение
Модуль предназначен для анализа контактов пользователя, поиска дубликатов, объединения повторяющихся записей, удаления пустых/битых контактов и оптимизации телефонной книги.  
Это классический функционал utility-клинеров, часто используемый в связке с фото-чисткой.

Цели:
- Упростить телефонную книгу
- Удалить мусорные контакты
- Объединить одинаковые или очень похожие записи
- Выявить контакты без имени, номера или данных
- Сильно увеличить ощущение “почистил телефон”, что хорошо влияет на конверсию в подписку

---

# Структура модуля

## Главный экран: Contacts Cleaner Dashboard

### UI

**Заголовок:** Contacts Cleaner  
**Подзаголовок:** “Keep your address book clean and organized.”

**Статус-виджет с местом:**
- “You have X duplicate contacts”
- “Y incomplete contacts”
- “Z contacts with similar names”

**Основные категории (карточки):**

1. **Duplicate Contacts**  
   - описание: контакты, у которых совпадают имена, номера или email  
   - пример: “12 duplicates found”

2. **Similar Names**  
   - контакты, отличающиеся на 1–2 символа;  
     пример: “Anna Petrova” и “Ana Petrova”

3. **No Name Contacts**  
   - контакты, где есть номер, но нет имени

4. **No Number Contacts**  
   - контакты, где имя есть, а номера нет

5. **Empty Contacts**  
   - полностью пустые записи (часто создаются при синхронизации)

**Поведение карточек:**
- тап → открывает детальный экран категории

---

# Детальный экран категории (пример: Duplicate Contacts)

## UI

**Заголовок:** Duplicate Contacts  
**Список групп дубликатов**  
Каждая группа содержит несколько контактов:

Пример блока:
- Group 1:
  - “Anna Petrova, +1 234 567”
  - “A. Petrova, +1 234 567”
  - mini-checkmark для выбора

**Side-by-side сравнение**:
При тапе по группе → модальное окно “Review & Merge”:  
- слева старый контакт  
- справа новый  
- снизу список полей (имя/телефон/email)  
- выделение различий цветом

### CTA:
- **Merge** (объединить в один контакт)  
- **Keep Separate**  
- **Delete Contact** (если пустой)

---

# Правила логики

## 1. Обнаружение дубликатов
Алгоритм проверяет:

1) Полное совпадение имени  
2) Полное совпадение номера  
3) Частичное совпадение имени (расстояние Левенштейна ≤ 2)  
4) Совпадение email  
5) Контакты, созданные подряд (system timestamp proximity)  
6) Контакты с одинаковыми company/job fields

Каждая пара получает «score»:

- 0–30 → разные  
- 30–60 → похожие  
- 60–100 → дубликаты  

Группируем в кластеры.

---

## 2. Объединение контактов
При Merge:
- создаётся новый CNMutableContact
- объединяются поля:
  - имя: берём самое длинное и полное
  - номер: объединяем списком
  - email: объединяем
  - company/job: если в одном пусто — берём из второго
- удаляем исходные контакты
- сохраняем новый

Логировать:
- `contacts_merge_started`
- `contacts_merge_completed`
- `contacts_merge_error`

---

## 3. Удаление пустых контактов

Пустой контакт — это запись, где:
- нет имени,
- нет номера,
- нет email,
- нет заметок,
- нет дат/компании.

Такие записи удаляются сразу с подтверждением.

---

## 4. Работа с Similar Names
Поиск по алгоритму расстояния Левенштейна:
- “Алекей” → “Алексей”
- “Mariya” → “Maria”

Пользователь может:
- объединить  
- переименовать один  
- игнорировать  

---

## 5. Работа с контактами без номера
Эти контакты часто мусорные.

Опции:
- Delete  
- Edit → добавить номер  
- Ignore

---

## 6. Работа с контактами без имени
Показываем список:
- номера → без имени  
- сортируем по активности (если данные доступны)

Опции:
- Add name  
- Delete  
- Ignore

---

# Нижняя панель действий (Action Bar)
Включается в режиме множественного выбора:

- “Delete X contacts”
- “Merge X groups”
- “Fix Names”
- “Fix Missing Numbers”

---

# Системные ограничения и edge-cases

1. **iCloud Sync**  
   - контакт может быть не удалён сразу  
   - показываем статус “Syncing with iCloud”

2. **Read-only sources (Exchange, company accounts)**  
   - невозможно удалять/редактировать  
   - показываем серую пометку “Read-only”

3. **Нет разрешения на контакты**  
   - показываем блокирующий экран:  
     **“Contacts access is required to clean your address book”**  
     CTA → Settings

4. **Очень большая адресная книга (2000+ контактов)**  
   - отображаем индикатор прогресса  
   - сканируем по батчам

---

# Аналитика

- `contacts_cleaner_opened`
- `contacts_duplicates_opened`
- `contacts_duplicates_merge`
- `contacts_duplicates_keep`
- `contacts_similar_names_opened`
- `contacts_no_number_opened`
- `contacts_no_name_opened`
- `contacts_empty_opened`
- `contacts_bulk_delete`
- `contacts_bulk_merge`
- `contacts_edit_opened`
- `contacts_permission_denied`
- `contacts_permission_granted`

Ошибки:
- `contacts_write_error`
- `contacts_delete_error`
- `contacts_merge_conflict`

---

# Основные переходы

- Dashboard → Contacts Cleaner  
- Contacts Cleaner → Duplicate Contacts  
- Contacts Cleaner → Similar Names  
- Contacts Cleaner → No Number Contacts  
- Contacts Cleaner → No Name Contacts  
- Contacts Cleaner → Empty Contacts  
- Any screen → Paywall (если free-limit исчерпан)  
- Contacts Preview → iOS Edit Contact  

