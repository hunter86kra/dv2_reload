Config = {}

Config.Command = 'dv2'
Config.MySQL = 'oxmysql' -- 'oxmysql' or 'mysql-async'
Config.VehicleTable = 'owned_vehicles'
Config.ReloadDistance = 5.0
Config.CommandCooldownMs = 10000
Config.RepairAfterReload = true

Config.Messages = {
    noVehicle = 'Kein Fahrzeug im Umkreis von 5 Metern gefunden.',
    missingPlate = 'Kennzeichen konnte nicht gelesen werden.',
    loading = 'Fahrzeug wird aus der Datenbank neu geladen...',
    notFound = 'Zu diesem Kennzeichen wurden keine Fahrzeugdaten in der Datenbank gefunden.',
    invalidData = 'Fahrzeugdaten konnten nicht geladen werden.',
    dbOffline = 'Keine gueltige MySQL-Anbindung gefunden.',
    noControl = 'Fahrzeug konnte nicht uebernommen werden. Versuch es erneut.',
    spawnFailed = 'Fahrzeug konnte nicht neu gespawnt werden.',
    cooldown = 'Bitte warte kurz, bevor du /dv2 erneut nutzt.',
    success = 'Dein Fahrzeug wurde neu geladen. Der Datenbankeintrag blieb unveraendert.'
}
