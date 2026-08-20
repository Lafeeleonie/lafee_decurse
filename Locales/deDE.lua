local _, addon = ...
addon.Locales = addon.Locales or {}

addon.Locales.deDE = {
    CLICK_LEFT = "Linksklick", CLICK_RIGHT = "Rechtsklick", CLICK_MIDDLE = "Mittelklick",
    CLICK_SHORT_LEFT = "L", CLICK_SHORT_RIGHT = "R", CLICK_SHORT_MIDDLE = "M",
    CONFIG_SUBTITLE = "Konfiguration des sicheren Gruppenfensters für Bannung und Hilfszauber",
    SECTION_INTERFACE = "Oberfläche", LOCK_FRAME = "Fenster sperren", SHOW_MINIMAP = "Minikartensymbol anzeigen", RESET_POSITION = "Position zurücksetzen",
    UNASSIGNED = "Nicht belegt",
    MINIMAP_TOGGLE = "Linksklick: ein-/ausblenden", MINIMAP_CONFIG = "Rechtsklick: Konfiguration", MINIMAP_DRAG = "Ziehen: verschieben",
    LOCK_COMBAT = "Die Sperre kann im Kampf nicht geändert werden.", FRAME_LOCKED = "Fenster gesperrt.", FRAME_UNLOCKED = "Fenster entsperrt.",
    POSITION_COMBAT = "Die Position kann im Kampf nicht geändert werden.", POSITION_RESET = "Position zurückgesetzt.",
    VISIBILITY_COMBAT = "Das Fenster kann im Kampf nicht ein- oder ausgeblendet werden.", NO_DISPEL = "Kein unterstützter freundlicher Bannzauber ist bekannt.",
    NO_ACTION = "Für die Klickaktionen ist kein Zauber konfiguriert.",
    AURA_CONTAINER_FAILED = "Blizzard_AuraContainer konnte nicht geladen werden: %s", AURA_DISPLAY_FAILED = "Die Schaltflächen sind verfügbar, aber die Auraanzeige konnte nicht erstellt werden.",
    INIT_DEFERRED = "Initialisierung bis zum Ende des Kampfes verschoben.", TEST_ENABLED = "Visueller Test aktiviert.", TEST_DISABLED = "Visueller Test deaktiviert.",
    TEST_COMBAT = "Der visuelle Test kann im Kampf nicht geändert werden.", HELP_LOCK = "/ldec lock — Fenster sperren oder entsperren",
    HELP_TEST = "/ldec test — visuellen Test ein- oder ausschalten", HELP_CONFIG = "/ldec config — Konfiguration öffnen", HELP_MINIMAP = "/ldec minimap — Minikartensymbol ein- oder ausblenden",
    TEST_MODE = "Testauren anzeigen", SECTION_APPEARANCE = "Aussehen", SHOW_TITLE = "Addontitel anzeigen", SHOW_NAMES = "Spielernamen anzeigen",
    SHOW_BACKGROUND = "Fensterhintergrund anzeigen", BACKGROUND_MODE = "Hintergrund", BACKGROUND_MODE_FULL = "Gesamter Rahmen", BACKGROUND_MODE_FRAMES = "Nur Spielerrahmen", BACKGROUND_MODE_NONE = "Kein Hintergrund",
    CLASS_COLORS = "Fenster nach Klasse färben", HORIZONTAL_LAYOUT = "Horizontale Spieleranordnung", BACKGROUND_COLOR = "Hintergrundfarbe", RESET_COLOR = "Farbe zurücksetzen",
    DISPLAY_COMBAT = "Anzeigeeinstellungen können im Kampf nicht geändert werden.",
    AURA_COUNT = "Anzahl der Auren", AURA_GROWTH = "Aurenrichtung", GROWTH_LEFT = "Links", GROWTH_RIGHT = "Rechts", GROWTH_UP = "Oben", GROWTH_DOWN = "Unten",
    SHOW_AURAS = "Aurasymbole anzeigen", AURA_GLOW = "Spielerrahmen hervorheben, wenn eine Bannung nötig ist",
    SECTION_GLOW = "Bannungsleuchten", GLOW_STYLE = "Stil", GLOW_STYLE_PULSE = "Pulsieren", GLOW_STYLE_ANTS = "Laufende Punkte", GLOW_STYLE_SOLID = "Statisch",
    GLOW_COLOR = "Farbe", GLOW_SPEED = "Geschwindigkeit", GLOW_THICKNESS = "Randstärke",
    ACTION_ASSIGNMENTS = "Klickaktionen", ACTION_NOTE = "Jeder Klick kann einen bekannten Zauber der aktuellen Spezialisierung wirken. Änderungen werden nur außerhalb des Kampfes angewendet.",
    ACTION_COMBAT = "Klickaktionen können im Kampf nicht geändert werden.", COOLDOWN_BAR = "Aufladung",
}
