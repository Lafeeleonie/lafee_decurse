local _, addon = ...

local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
local overrides = {
    enUS = {
        HORIZONTAL_LAYOUT = "Horizontal player layout",
    },
    frFR = {
        CONFIG_SUBTITLE = "Configuration du mini-cadre de groupe sécurisé pour la dissipation",
        SHOW_MINIMAP = "Afficher l’icône de minicarte",
        NO_DISPEL = "Aucun sort de dissipation utilisable sur les alliés n’est disponible.",
        SHOW_BACKGROUND = "Afficher le fond des cadres",
        BACKGROUND_MODE = "Fond",
        BACKGROUND_MODE_FULL = "Cadre complet",
        BACKGROUND_MODE_FRAMES = "Cadres des joueurs uniquement",
        BACKGROUND_MODE_NONE = "Aucun fond",
        HORIZONTAL_LAYOUT = "Disposition horizontale des joueurs",
        AURA_COUNT = "Nombre d’auras",
        AURA_GROWTH = "Croissance des auras",
        GROWTH_LEFT = "Gauche",
        GROWTH_RIGHT = "Droite",
        GROWTH_UP = "Haut",
        GROWTH_DOWN = "Bas",
        ACTION_ASSIGNMENTS = "Actions des clics",
        ACTION_NOTE = "Chaque clic peut lancer un sort connu de la spécialisation actuelle. Les changements sont appliqués uniquement hors combat.",
        ACTION_COMBAT = "Les actions des clics ne peuvent pas être modifiées en combat.",
        NO_ACTION = "Aucun sort n’est configuré sur les clics.",
        COOLDOWN_BAR = "Recharge",
        CLICK_SHORT_LEFT = "G",
        CLICK_SHORT_RIGHT = "D",
        CLICK_SHORT_MIDDLE = "M",
    },
    deDE = {
        BACKGROUND_MODE = "Hintergrund",
        BACKGROUND_MODE_FULL = "Gesamter Rahmen",
        BACKGROUND_MODE_FRAMES = "Nur Spielerrahmen",
        BACKGROUND_MODE_NONE = "Kein Hintergrund",
        HORIZONTAL_LAYOUT = "Horizontale Spieleranordnung",
    },
    esES = {
        BACKGROUND_MODE = "Fondo",
        BACKGROUND_MODE_FULL = "Marco completo",
        BACKGROUND_MODE_FRAMES = "Solo marcos de jugadores",
        BACKGROUND_MODE_NONE = "Sin fondo",
        HORIZONTAL_LAYOUT = "Disposición horizontal de jugadores",
    },
    itIT = {
        BACKGROUND_MODE = "Sfondo",
        BACKGROUND_MODE_FULL = "Riquadro completo",
        BACKGROUND_MODE_FRAMES = "Solo riquadri dei giocatori",
        BACKGROUND_MODE_NONE = "Nessuno sfondo",
        HORIZONTAL_LAYOUT = "Disposizione orizzontale dei giocatori",
    },
    ptBR = {
        BACKGROUND_MODE = "Fundo",
        BACKGROUND_MODE_FULL = "Quadro completo",
        BACKGROUND_MODE_FRAMES = "Apenas quadros dos jogadores",
        BACKGROUND_MODE_NONE = "Sem fundo",
        HORIZONTAL_LAYOUT = "Disposição horizontal dos jogadores",
    },
    ruRU = {
        BACKGROUND_MODE = "Фон",
        BACKGROUND_MODE_FULL = "Вся рамка",
        BACKGROUND_MODE_FRAMES = "Только рамки игроков",
        BACKGROUND_MODE_NONE = "Без фона",
        HORIZONTAL_LAYOUT = "Горизонтальное расположение игроков",
    },
    koKR = {
        BACKGROUND_MODE = "배경",
        BACKGROUND_MODE_FULL = "전체 프레임",
        BACKGROUND_MODE_FRAMES = "플레이어 프레임만",
        BACKGROUND_MODE_NONE = "배경 없음",
        HORIZONTAL_LAYOUT = "플레이어 가로 배치",
    },
    zhCN = {
        BACKGROUND_MODE = "背景",
        BACKGROUND_MODE_FULL = "整个框体",
        BACKGROUND_MODE_FRAMES = "仅玩家框体",
        BACKGROUND_MODE_NONE = "无背景",
        HORIZONTAL_LAYOUT = "横向玩家布局",
    },
    zhTW = {
        BACKGROUND_MODE = "背景",
        BACKGROUND_MODE_FULL = "整個框架",
        BACKGROUND_MODE_FRAMES = "僅玩家框架",
        BACKGROUND_MODE_NONE = "無背景",
        HORIZONTAL_LAYOUT = "橫向玩家排列",
    },
}

overrides.enGB = overrides.enUS
overrides.esMX = overrides.esES

for key, value in pairs(overrides[locale] or {}) do
    addon.L[key] = value
end

-- New strings use English as a temporary fallback until the localization
-- folder refactor gives every supported locale its own table.
addon.L.AURA_COUNT = addon.L.AURA_COUNT or "Aura count"
addon.L.AURA_GROWTH = addon.L.AURA_GROWTH or "Aura growth"
addon.L.GROWTH_LEFT = addon.L.GROWTH_LEFT or "Left"
addon.L.GROWTH_RIGHT = addon.L.GROWTH_RIGHT or "Right"
addon.L.GROWTH_UP = addon.L.GROWTH_UP or "Up"
addon.L.GROWTH_DOWN = addon.L.GROWTH_DOWN or "Down"
addon.L.ACTION_ASSIGNMENTS = addon.L.ACTION_ASSIGNMENTS or "Click actions"
addon.L.ACTION_NOTE = addon.L.ACTION_NOTE or "Each click can cast a known spell from the current specialization. Changes are applied only out of combat."
addon.L.ACTION_COMBAT = addon.L.ACTION_COMBAT or "Click actions cannot be changed in combat."
addon.L.NO_ACTION = addon.L.NO_ACTION or "No spell is configured on the click actions."
addon.L.COOLDOWN_BAR = addon.L.COOLDOWN_BAR or "Cooldown"
addon.L.CLICK_SHORT_LEFT = addon.L.CLICK_SHORT_LEFT or "L"
addon.L.CLICK_SHORT_RIGHT = addon.L.CLICK_SHORT_RIGHT or "R"
addon.L.CLICK_SHORT_MIDDLE = addon.L.CLICK_SHORT_MIDDLE or "M"
