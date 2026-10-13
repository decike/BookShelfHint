BookShelfHint UE4SS v9

安装：
1. 先退出游戏。
2. 将 BookShelfHint 文件夹放入游戏的 UE4SS/Mods/ 目录，覆盖旧的 BookShelfHint 文件夹。
3. 确认 UE4SS/Mods/BookShelfHint/enabled.txt 存在并保持启用。
4. 删除旧的 BookShelfHint.log（可选），重新启动游戏。

显示：
- 手持书：书名右侧显示一个独立的白字提示；书架编号以 1 开头时为粉色描边，以 2 开头时为蓝色描边。
- 瞄准书：在原书名下方显示一个独立的白字提示，不带箭头；使用 CanvasPanel 的水平中心锚点居中，不根据书名字符数或提示文本宽度估算 X 坐标。颜色规则相同。
- 手持书提示字号会读取并同步原书名 TextBlock 的字体大小。
- 尝试清理 v4/v5 曾写入原书名控件的旧提示，原书名字体与样式不变。
- 按视觉行/面板复用提示控件，避免同一行重复创建提示。

日志：
BookShelfHint/BookShelfHint.log
如果瞄准提示仍未居中或垂直位置不正确，请提供新版日志中“CanvasPanel 位置设置失败”或“已创建独立提示 TextBlock”附近的内容。

注意：UE4SS 的 UMG 控件行为会受游戏具体 Widget 蓝图布局影响；本版本需要在游戏中验证实际位置。
