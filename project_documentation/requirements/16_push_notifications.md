# Краткое ТЗ для Cursor: Local Push Notifications

## Общие требования
- Использовать **Local Notifications** (`UNUserNotificationCenter`)
- Без сервера, без APNs, без Background Modes
- Уведомления должны приходить даже при полностью закрытом приложении

## Расписание
- 2 уведомления в день:
  - **09:45**
  - **17:45**
- Локальное время устройства

## Контент
- Использовать **12 вариантов текстов** (title + body)
- При создании каждого уведомления выбирать **случайный вариант**

## Планирование
- Планировать уведомления **на 14 дней вперёд**
- Для каждого дня создавать **2 отдельных уведомления** (утро/вечер)
- Использовать `UNCalendarNotificationTrigger` с `repeats = false`

## Поддержка окна
- При запуске приложения проверять количество дней, на которые уже есть запланированные уведомления
- Если осталось **меньше 5 дней** — удалять старые и **пересоздавать новые на 14 дней**

## Настройки
- В настройках приложения добавить toggle **Notifications On / Off**
- Состояние toggle хранить в `UserDefaults`
- При выключении:
  - удалять все запланированные уведомления приложения
- При включении:
  - запрашивать permission (если нужно)
  - при разрешении — планировать уведомления на 14 дней

## Интеграция
- Запрашивать разрешение на уведомления после онбординга (опционально)
- На старте приложения вызывать проверку и поддержку расписания

## Ограничения
- Не использовать `NSUserNotificationsUsageDescription` в Info.plist
- Не использовать remote push или сторонние сервисы

## Варианты уведомлений

Too Many Duplicates? 🧹
Remove duplicate photos and videos with one tap.

🧼 Refresh Your Gallery Now
Time to refresh your gallery? We're ready – just tap!

🚀 Free Up iPhone Storage Fast
Your iPhone will thank you – remove the clutter in seconds!

Compress Videos, Keep Quality 🎥
Save space without losing a pixel.

Let's Declutter! 💨
Don't let junk slow you down – clean it out now!

Instant Performance Boost 🔋
Free space, run smoother, feel the speed!

Your Storage Is Waiting 📱
Hidden clutter may be taking space — clean it in seconds.

Smart Cleanup Time ✨
Duplicates and similar files won’t remove themselves.

More Space, Less Noise 🧠
Keep only what matters — delete the rest easily.

Quick Scan, Big Win ⚡
One tap can free hundreds of megabytes.

Keep Your iPhone Light 🪶
Remove unnecessary photos and videos effortlessly.

Clean Today, Relax Tomorrow 😌
A quick cleanup keeps your phone running smoothly.