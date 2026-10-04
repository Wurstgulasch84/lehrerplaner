# Pinnwand

Deine eigene digitale Pinnwand, direkt auf deinem Home Assistant.

## Einrichten

1. Im Reiter **Konfiguration** den **GitHub-Zugangsschlüssel** eintragen und speichern.
2. Add-on starten. Beim ersten Start wird die Pinnwand geladen und gebaut, das dauert einige Minuten. Den Fortschritt zeigt der Reiter **Protokoll**.
3. **Web-Oberfläche öffnen**. Beim ersten Aufruf legst du dein Konto an.

## Adresse

- Zu Hause: `http://<IP des Home Assistant>:3190`
- Unterwegs mit der Tailscale-App: dieselbe Adresse, weil Tailscale dein Heimnetz weiterreicht.

## Daten

Datenbank und Dateien liegen im Ordner `addon_configs/…_pinnwand` (über die Samba-Freigabe erreichbar)
und sind in jeder Home-Assistant-Sicherung enthalten.
Vorhandene Daten vom PC übernehmen: Add-on stoppen, `database.sqlite` nach `database/` und den Inhalt
von `uploads/` nach `uploads/` kopieren, Add-on starten.

## Updates

Bei jedem Neustart holt sich das Add-on den neuesten Stand der Pinnwand und baut ihn, falls sich etwas geändert hat.
