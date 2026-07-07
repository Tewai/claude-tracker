# Návod: obnova cookie v Safari

Použij, když Claude Pulse ukáže chybu **„HTTP 403 — cookie may have expired"**.

## Jednorázová příprava (pokud chybí menu Vývoj)

Safari → **Nastavení → Pokročilé** → zaškrtnout **„Zobrazit funkce pro webové vývojáře"**.

## Postup

1. Otevři [claude.ai](https://claude.ai) a přihlas se.
2. Stiskni **Cmd + Option + I** (otevře se Web Inspector) → záložka **Síť** (Network).
3. Stiskni **Cmd + R** — stránka se obnoví a seznam požadavků se naplní.
4. Do filtru nahoře napiš **`bootstrap`** a klikni na nalezený požadavek.
5. V detailu požadavku (panel vedle seznamu) sjeď na **záhlaví požadavku** (Request Headers)
   a najdi řádek **`Cookie`**.
6. Pravý klik na hodnotu → **Zkopírovat hodnotu** (je to jeden velmi dlouhý řetězec).
   - ⚠️ Nepoužívej „Kopírovat jako cURL" — Safari do něj cookie nedává.
7. V menu baru klikni na ikonu **Claude Pulse** → tlačítko **Cookie** →
   vlož zkopírovaný řetězec → **Next →** → Org ID nech beze změny → **Save**.

Aplikace hned načte čerstvá data. Hotovo.
