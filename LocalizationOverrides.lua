local _, addon = ...

local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
local overrides = {
    frFR = {
        CONFIG_SUBTITLE = "Configuration du mini-cadre de groupe sécurisé pour la dissipation",
        SHOW_MINIMAP = "Afficher l’icône de minicarte",
        NO_DISPEL = "Aucun sort de dissipation utilisable sur les alliés n’est disponible.",
        SHOW_BACKGROUND = "Afficher le fond des cadres",
        BACKGROUND_MODE = "Fond",
        BACKGROUND_MODE_FULL = "Cadre complet",
        BACKGROUND_MODE_FRAMES = "Cadres des joueurs uniquement",
        BACKGROUND_MODE_NONE = "Aucun fond",
    },
    deDE = {
        BACKGROUND_MODE = "Hintergrund",
        BACKGROUND_MODE_FULL = "Gesamter Rahmen",
        BACKGROUND_MODE_FRAMES = "Nur Spielerrahmen",
        BACKGROUND_MODE_NONE = "Kein Hintergrund",
    },
    esES = {
        BACKGROUND_MODE = "Fondo",
        BACKGROUND_MODE_FULL = "Marco completo",
        BACKGROUND_MODE_FRAMES = "Solo marcos de jugadores",
        BACKGROUND_MODE_NONE = "Sin fondo",
    },
    itIT = {
        BACKGROUND_MODE = "Sfondo",
        BACKGROUND_MODE_FULL = "Riquadro completo",
        BACKGROUND_MODE_FRAMES = "Solo riquadri dei giocatori",
        BACKGROUND_MODE_NONE = "Nessuno sfondo",
    },
    ptBR = {
        BACKGROUND_MODE = "Fundo",
        BACKGROUND_MODE_FULL = "Quadro completo",
        BACKGROUND_MODE_FRAMES = "Apenas quadros dos jogadores",
        BACKGROUND_MODE_NONE = "Sem fundo",
    },
    ruRU = {
        BACKGROUND_MODE = "Фон",
        BACKGROUND_MODE_FULL = "Вся рамка",
        BACKGROUND_MODE_FRAMES = "Только рамки игроков",
        BACKGROUND_MODE_NONE = "Без фона",
    },
    koKR = {
        BACKGROUND_MODE = "배경",
        BACKGROUND_MODE_FULL = "전체 프레임",
        BACKGROUND_MODE_FRAMES = "플레이어 프레임만",
        BACKGROUND_MODE_NONE = "배경 없음",
    },
    zhCN = {
        BACKGROUND_MODE = "背景",
        BACKGROUND_MODE_FULL = "整个框体",
        BACKGROUND_MODE_FRAMES = "仅玩家框体",
        BACKGROUND_MODE_NONE = "无背景",
    },
    zhTW = {
        BACKGROUND_MODE = "背景",
        BACKGROUND_MODE_FULL = "整個框架",
        BACKGROUND_MODE_FRAMES = "僅玩家框架",
        BACKGROUND_MODE_NONE = "無背景",
    },
}

overrides.esMX = overrides.esES

for key, value in pairs(overrides[locale] or {}) do
    addon.L[key] = value
end
