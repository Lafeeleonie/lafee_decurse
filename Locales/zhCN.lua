local _, addon = ...
addon.Locales = addon.Locales or {}

addon.Locales.zhCN = {
    CLICK_LEFT = "左键点击", CLICK_RIGHT = "右键点击", CLICK_MIDDLE = "中键点击",
    CLICK_SHORT_LEFT = "左", CLICK_SHORT_RIGHT = "右", CLICK_SHORT_MIDDLE = "中",
    CONFIG_SUBTITLE = "安全驱散与辅助技能小队框架设置",
    SECTION_INTERFACE = "界面", LOCK_FRAME = "锁定框架", SHOW_MINIMAP = "显示小地图图标", RESET_POSITION = "重置位置",
    UNASSIGNED = "未分配",
    MINIMAP_TOGGLE = "左键：显示/隐藏", MINIMAP_CONFIG = "右键：设置", MINIMAP_DRAG = "拖动：移动",
    LOCK_COMBAT = "战斗中无法更改锁定状态。", FRAME_LOCKED = "框架已锁定。", FRAME_UNLOCKED = "框架已解锁。",
    POSITION_COMBAT = "战斗中无法更改位置。", POSITION_RESET = "位置已重置。",
    VISIBILITY_COMBAT = "战斗中无法显示或隐藏框架。", NO_DISPEL = "未发现支持的友方驱散法术。",
    NO_ACTION = "点击动作未配置任何法术。",
    AURA_CONTAINER_FAILED = "无法加载 Blizzard_AuraContainer：%s", AURA_DISPLAY_FAILED = "按钮可用，但无法创建光环显示。",
    INIT_DEFERRED = "初始化推迟到战斗结束。", TEST_ENABLED = "视觉测试已启用。", TEST_DISABLED = "视觉测试已禁用。",
    TEST_COMBAT = "战斗中无法更改视觉测试。", HELP_LOCK = "/ldec lock — 锁定或解锁框架",
    HELP_TEST = "/ldec test — 开关视觉测试", HELP_CONFIG = "/ldec config — 打开设置", HELP_MINIMAP = "/ldec minimap — 显示或隐藏小地图图标",
    TEST_MODE = "显示测试光环", SECTION_APPEARANCE = "外观", SHOW_TITLE = "显示插件标题", SHOW_NAMES = "显示玩家名称",
    SHOW_BACKGROUND = "显示框体背景", BACKGROUND_MODE = "背景", BACKGROUND_MODE_FULL = "整个框体", BACKGROUND_MODE_FRAMES = "仅玩家框体", BACKGROUND_MODE_NONE = "无背景",
    CLASS_COLORS = "按职业着色框体", HORIZONTAL_LAYOUT = "横向玩家布局", BACKGROUND_COLOR = "背景颜色", RESET_COLOR = "重置颜色",
    DISPLAY_COMBAT = "战斗中无法更改显示设置。",
    AURA_COUNT = "光环数量", AURA_GROWTH = "光环延伸方向", GROWTH_LEFT = "向左", GROWTH_RIGHT = "向右", GROWTH_UP = "向上", GROWTH_DOWN = "向下",
    SHOW_AURAS = "显示光环图标", AURA_GLOW = "需要驱散时高亮玩家框体",
    ACTION_ASSIGNMENTS = "点击动作", ACTION_NOTE = "每个点击都可以施放当前专精已学会的法术。更改仅在非战斗状态下应用。",
    ACTION_COMBAT = "战斗中无法更改点击动作。", COOLDOWN_BAR = "充能",
}
