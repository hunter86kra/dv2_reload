FiveM-Resource fuer ESX, mit der ein gespeichertes Owned Vehicle per /dv2 direkt aus der Datenbank neu geladen werden kann.

Was das Script macht
sucht ein Fahrzeug im Umkreis des Spielers
liest das Kennzeichen des Fahrzeugs aus
laedt die gespeicherten Fahrzeugdaten aus der Datenbank
loescht das aktuelle Fahrzeug und spawnt es mit den gespeicherten Properties neu
setzt den Spieler wieder auf den Fahrersitz, wenn er vorher gefahren ist
repariert das Fahrzeug nach dem Reload optional automatisch
aendert den Datenbankeintrag dabei nicht
Das ist praktisch, wenn ein Fahrzeug verbuggt ist, falsche Fahrzeugdaten hat oder schnell auf den gespeicherten Zustand zurueckgesetzt werden soll.

Voraussetzungen
es_extended
oxmysql oder mysql-async
eine Fahrzeugtabelle wie owned_vehicles
in der Tabelle muessen mindestens plate und vehicle vorhanden sein
Befehl
/dv2 laedt das naechste Fahrzeug im konfigurierten Radius aus der Datenbank neu
Standardverhalten
Radius zum Fahrzeug: 5.0 Meter
Command-Cooldown: 10000 Millisekunden
Standard-Datenbanktreiber: oxmysql
Standard-Tabelle: owned_vehicles
Reparatur nach Reload: aktiviert
Installation
Lege den Ordner dv2_reload in deinen Resources-Ordner.
Stelle sicher, dass es_extended und dein MySQL-Resource vor dv2_reload gestartet werden.
Trage das Script in deine server.cfg ein.
Beispiel mit oxmysql:

ensure es_extended
ensure oxmysql
ensure dv2_reload
Beispiel mit mysql-async:

ensure es_extended
ensure mysql-async
ensure dv2_reload
Passe bei Bedarf die Werte in config.lua an.
Starte die Resource neu und teste /dv2 an einem Fahrzeug, das in deiner Owned-Vehicle-Tabelle gespeichert ist.
Konfiguration
Die wichtigsten Optionen in config.lua:

Config.Command = 'dv2'
Config.MySQL = 'oxmysql'
Config.VehicleTable = 'owned_vehicles'
Config.ReloadDistance = 5.0
Config.CommandCooldownMs = 10000
Config.RepairAfterReload = true
Bedeutung:

Config.Command: Name des Befehls
Config.MySQL: verwendeter Datenbanktreiber, entweder oxmysql oder mysql-async
Config.VehicleTable: Tabelle, aus der die Fahrzeugdaten gelesen werden
Config.ReloadDistance: maximale Entfernung zum Ziel-Fahrzeug
Config.CommandCooldownMs: Wartezeit zwischen zwei Nutzungen des Befehls
Config.RepairAfterReload: bestimmt, ob das Fahrzeug nach dem Reload voll repariert wird
Datenbanklogik
Das Script sucht in der konfigurierten Tabelle nach einem Eintrag, dessen Kennzeichen zum Fahrzeug im Spiel passt. Dabei werden Leerzeichen aus dem Kennzeichen entfernt und alles in Grossbuchstaben verglichen. Anschliessend wird der Inhalt aus der vehicle-Spalte als JSON gelesen und fuer das neu gespawnte Fahrzeug verwendet.

Standard-Query:

SELECT plate, vehicle
FROM owned_vehicles
WHERE REPLACE(UPPER(plate), ' ', '') = @plate
LIMIT 1
Wenn dein Framework eine andere Tabellenstruktur oder andere Spaltennamen nutzt, musst du die Abfrage in server.lua anpassen.

Hinweise
Das Fahrzeug muss sich innerhalb des konfigurierten Radius befinden.
Wenn der Spieler bereits im Fahrzeug sitzt, versucht das Script ihn sauber aussteigen zu lassen und danach wieder hinein zu setzen.
Wenn kein gueltiger Datenbankeintrag gefunden wird, wird kein neues Fahrzeug erstellt.
Wenn es_extended keine erweiterten Vehicle-Property-Funktionen bereitstellt, wird mindestens das Kennzeichen auf das neue Fahrzeug uebertragen.
Dateien
Manifest: fxmanifest.lua
Config: config.lua
Client: client.lua
Server: server.lua
