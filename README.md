# BookShelfHint

> 《图书管理员：整理魔法图书馆吧！》UE4SS Mod

显示**手持书本**与**当前瞄准书本**所属的 **书架号** 和 **书架名**，帮助快速归位。

## 效果预览

![效果预览](./preview.gif)

## 功能特性

- 📚 显示手持书本所属的书架号与书架名
- 🎯 显示准星瞄准书本所属的书架号与书架名
- ⚡ 一二楼的书架提示显示不同颜色，更方便查看

## 使用方法

### 安装

1. 前往本仓库的 [Releases](../../releases/latest) 页面，下载最新的**全量包**（`.zip`）。
2. 解压下载的压缩包，得到 `ue4ss` 文件夹和 `dwmapi.dll`。
3. 在 Steam（或你所使用的游戏平台）中，右键游戏 → **管理** → **浏览本地文件**。
4. 依次打开 `\Librarian` → `\Binaries` → `\Win64`。
5. 将解压出来的 `\ue4ss` 文件夹和 `dwmapi.dll` 一起粘贴到该目录下。
6. 重新启动游戏，即可看到 Mod 效果。

安装完成后的目录结构大致如下：

```
...\Librarian Tidy Up the Arcane Library!\Librarian\Binaries\Win64\
├── Librarian-Win64-Shipping.exe
├── dwmapi.dll        ← 粘贴进来的
└── ue4ss\            ← 粘贴进来的
```

### 卸载

1. 打开 `...\Librarian Tidy Up the Arcane Library!\Librarian\Binaries\Win64\` 目录。
2. 删除 `\ue4ss` 文件夹和 `dwmapi.dll`。
3. 重新启动游戏即可，游戏恢复原状。

## 项目结构

```
BookShelfHint/
├── ue4ss/                                  # UE4SS 本体
│   └── Mods/
│       └── BookShelfHint/
│           └── Scripts/
│               └── main.lua                # ★ Mod 核心代码
├── dwmapi.dll                              # UE4SS 注入用的代理 DLL
├── preview.gif
└── README.md
```

> 核心代码为 `BookShelfHint\ue4ss\Mods\BookShelfHint\Scripts\main.lua`，感兴趣的可以去研究。
> 除 `BookShelfHint`（即 `ue4ss\Mods\BookShelfHint\`）之外的部分，均为 UE4SS 自带文件。

## 说明

- 本项目的大部分代码和文档由 **AI（大语言模型）辅助生成**，仅供个人学习使用。
- 请勿用于任何商业用途。
- 使用本 Mod 产生的任何后果由使用者自行承担。

## 致谢

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) —— 提供脚本注入与 Mod 加载框架