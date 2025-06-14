# 🎮 經典 Square Onix RPG 戰鬥模擬器

一款使用 Flutter 製作的經典日式 RPG 回合制戰鬥模擬器，結合了升級系統、ATB 行動條、技能與魔法、敵人隨機生成與生存時間紀錄功能。靈感來自 Final Fantasy 風格！

## 🧩 功能介紹

- 🗡️ 普通攻擊與技能系統（突刺、斬擊、重擊）
- 🔥 四種魔法（火焰、冰結、雷電、回復）
- 🧠 ATB（Active Time Battle）機制：玩家與敵人行動需等待蓄力條填滿
- ⏱️ 生存時間計時，並紀錄最佳成績（SharedPreferences）
- 🎵 BGM / SFX 音效與背景音樂
- 💥 傷害文字與流血/燃燒等異常狀態
- 🧪 隨機敵人生成與魔石掉落
- 🌄 自訂主選單與背景圖片、角色/敵人圖像顯示

---

## 🚀 安裝與執行

1. 安裝 Flutter 環境：[Flutter 官方教學](https://docs.flutter.dev/get-started/install)
2. clone 專案：

   ```bash
   git clone https://github.com/你的帳號/square-onix-rpg.git
   cd square-onix-rpg
   ```
3. 安裝依賴套件：

   ```bash
   flutter pub get
   ```
4. 放置你的音效與圖片：

   * 將圖片放入 `images/` 目錄，例如：

     * `background.png`
     * `homepage.png`
     * `hero.png`
     * `enemy1.png`, `enemy2.png`, `enemy3.png`
   * 將音效放入 `assets/sfx/` 與 `assets/bgm/`：

     * `battle.mp3`
     * `attack.wav`, `heal.wav`, `enemy_attack.wav`, `level.wav`
5. 執行專案：

   ```bash
   flutter run
   ```

---

## 📁 資源目錄結構

```
assets/
├── bgm/
│   └── battle.mp3
├── sfx/
│   ├── attack.wav
│   ├── heal.wav
│   ├── enemy_attack.wav
│   └── level.wav
images/
├── homepage.png
├── background.png
├── hero.png
├── enemy1.png
├── enemy2.png
└── enemy3.png
```

記得在 `pubspec.yaml` 中加入：

```yaml
flutter:
  assets:
    - images/
    - assets/bgm/
    - assets/sfx/
```

---

## 🔮 開發技術

* Flutter
* Dart
* [audioplayers](https://pub.dev/packages/audioplayers)
* [shared\_preferences](https://pub.dev/packages/shared_preferences)

---

## ❤️ 致謝與授權

本遊戲純為學習與練習用途。角色素材、音樂可自行替換，建議使用開源或自行繪製素材。

---
