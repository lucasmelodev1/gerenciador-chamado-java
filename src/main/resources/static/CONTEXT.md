# src/main/resources/static

CSS/JS servidos direto pelo Spring e incluídos pelos fragmentos JSP.

- `css/`: `base`, `layout`, `components`, `responsive` e `calendar` (tema do FullCalendar).
- `js/`: `core`, `layout`, `forms`, `tables`, `alerts` e `calendar.js` (agendas mês/semana do admin e do morador).
- `js/vendor/fullcalendar/`, `css/vendor/fullcalendar/`: FullCalendar 7.1.0 vendorizado para uso offline, carregado quando a view define `calendarAssets`.
