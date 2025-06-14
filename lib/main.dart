import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SquareOnixRPG());

class SquareOnixRPG extends StatelessWidget {
  const SquareOnixRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '經典Square Onix RPG戰鬥模擬器',
      home: const MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int bestTime = 0;

  @override
  void initState() {
    super.initState();
    _loadBestTime();
  }

  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => bestTime = prefs.getInt('bestTime') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('images/homepage.png', fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '經典Square Onix RPG戰鬥模擬器',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  '歷史最長生存時間: $bestTime 秒',
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScene()),
                  ),
                  child: const Text('開始遊戲'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameScene extends StatefulWidget {
  const GameScene({super.key});

  @override
  State<GameScene> createState() => _GameSceneState();
}

class _GameSceneState extends State<GameScene> {
  int maxHP = 100;
  int currentHP = 100;
  int level = 1;
  int attack = 10;
  int ap = 0;
  int survivalSeconds = 0;

  double playerATB = 0.0;
  double enemyATB = 0.0;
  bool canAct = false;
  bool isPaused = false;

  final AudioPlayer bgmPlayer = AudioPlayer();
  final AudioPlayer sfxPlayer = AudioPlayer();
  late Timer gameTimer;
  late Timer atbTimer;
  final Random rng = Random();

  int fireStones = 0;
  int iceStones = 0;
  int thunderStones = 0;
  int healStones = 0;

  int enemyHP = 80;
  String enemyName = '';
  String enemyImage = '';

  String warningMessage = '';

  final List<String> enemies = ['enemy1.png', 'enemy2.png', 'enemy3.png'];
  final List<String> enemyNames = ['史萊姆', '哥布林', '飛龍'];

  bool showMainMenu = true;
  bool showSkillMenu = false;
  bool showMagicMenu = false;

  int bleedingTurns = 0;
  int burningTurns = 0;

  bool showDamage = false;
  String damageText = '';
  Color damageColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    _randomizeEnemy();
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.play(AssetSource('bgm/battle.mp3'));

    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused)
        setState(() {
          survivalSeconds++;
          _applyStatusEffects();
        });
    });

    atbTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isPaused)
        setState(() {
          if (playerATB < 1.0) playerATB += 0.02;
          if (enemyATB < 1.0) enemyATB += 0.015;
          if (playerATB >= 1.0 && !canAct) {
            canAct = true;
            isPaused = true;
          }
          if (enemyATB >= 1.0) _enemyAction();
        });
    });
  }

  void _applyStatusEffects() {
    if (bleedingTurns > 0) {
      int dmg = (attack * 0.2).toInt();
      enemyHP -= dmg;
      _showDamageText('-$dmg (流血)', Colors.red);
      bleedingTurns--;
    }
    if (burningTurns > 0) {
      int dmg = (attack * 0.2).toInt();
      enemyHP -= dmg;
      _showDamageText('-$dmg (燃燒)', Colors.orange);
      burningTurns--;
    }
    if (enemyHP <= 0) _onEnemyDefeat();
  }

  void _randomizeEnemy() {
    int idx = rng.nextInt(enemies.length);
    enemyImage = enemies[idx];
    enemyName = enemyNames[idx];
    enemyHP = 50 + rng.nextInt(100);
  }

  void _playerAttack([double mult = 1.0]) {
    if (!canAct) return;
    sfxPlayer.play(AssetSource('sfx/attack.wav'));
    setState(() {
      int dmg = (attack * mult).toInt();
      enemyHP -= dmg;
      _showDamageText('-$dmg', Colors.yellow);
      ap += 10;
      if (enemyHP <= 0) _onEnemyDefeat();
      _resumeAfterAction();
    });
  }

  void _onEnemyDefeat() {
    _dropItems();
    level++;
    attack += 2;
    maxHP += 10;
    sfxPlayer.play(AssetSource('sfx/level.wav'));
    _randomizeEnemy();
    bleedingTurns = 0;
    burningTurns = 0;
  }

  void _useSkill(String type) {
    if (!canAct) return;
    switch (type) {
      case 'thrust':
        if (ap >= 10) {
          ap -= 10;
          _playerAttack();
          playerATB = 0.5;
        } else
          _showWarning('AP 不足');
        break;
      case 'slash':
        if (ap >= 35) {
          ap -= 35;
          _playerAttack(1.5);
        } else
          _showWarning('AP 不足');
        break;
      case 'strike':
        if (ap >= 25) {
          ap -= 25;
          bleedingTurns = 2;
          _playerAttack();
        } else
          _showWarning('AP 不足');
        break;
    }
  }

  void _useMagic(String type) {
    if (!canAct) return;
    switch (type) {
      case 'fire':
        if (fireStones > 0) {
          fireStones--;
          burningTurns = 2;
          _playerAttack();
        } else
          _showWarning('火焰魔石不足');
        break;
      case 'ice':
        if (iceStones > 0) {
          iceStones--;
          _playerAttack();
          enemyATB = 0.0;
        } else
          _showWarning('冰結魔石不足');
        break;
      case 'thunder':
        if (thunderStones > 0) {
          thunderStones--;
          _playerAttack(1.5);
        } else
          _showWarning('雷電魔石不足');
        break;
      case 'heal':
        if (healStones > 0) {
          healStones--;
          sfxPlayer.play(AssetSource('sfx/heal.wav'));
          int heal = (maxHP * 0.2).toInt();
          currentHP = min(currentHP + heal, maxHP);
          _showDamageText('+\$heal HP', Colors.green);
          _resumeAfterAction();
        } else
          _showWarning('回復魔石不足');
        break;
    }
  }

  void _enemyAction() {
    sfxPlayer.play(AssetSource('sfx/enemy_attack.wav'));
    int dmg = 5 + rng.nextInt(10);
    setState(() {
      currentHP -= dmg;
      _showDamageText('-$dmg', Colors.redAccent);
      if (currentHP <= 0) _gameOver();
      enemyATB = 0.0;
    });
  }

  void _dropItems() {
    if (rng.nextBool()) fireStones++;
    if (rng.nextInt(3) == 0) iceStones++;
    if (rng.nextInt(4) == 0) thunderStones++;
    if (rng.nextBool()) healStones++;
  }

  void _showWarning(String msg) {
    setState(() => warningMessage = msg);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => warningMessage = '');
    });
  }

  void _showDamageText(String txt, Color col) {
    setState(() {
      showDamage = true;
      damageText = txt;
      damageColor = col;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => showDamage = false);
    });
  }

  void _resumeAfterAction() {
    playerATB = 0.0;
    canAct = false;
    showMainMenu = true;
    showSkillMenu = false;
    showMagicMenu = false;
    isPaused = false;
  }

  void _gameOver() async {
    bgmPlayer.stop();
    gameTimer.cancel();
    atbTimer.cancel();
    final prefs = await SharedPreferences.getInstance();
    if (survivalSeconds > (prefs.getInt('bestTime') ?? 0)) {
      await prefs.setInt('bestTime', survivalSeconds);
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('你輸了'),
        content: Text('你生存了 $survivalSeconds 秒'),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('回主選單'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    bgmPlayer.dispose();
    sfxPlayer.dispose();
    gameTimer.cancel();
    atbTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('images/background.png', fit: BoxFit.cover),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Column(children: [
                          Text('HP: $currentHP/$maxHP',
                              style: const TextStyle(color: Colors.white)),
                          Text('AP: $ap',
                              style: const TextStyle(color: Colors.white)),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Column(children: [
                          Text('LV: $level',
                              style: const TextStyle(color: Colors.white)),
                          Text('生存: $survivalSeconds 秒',
                              style: const TextStyle(color: Colors.white)),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Column(children: [
                          Text('LV: $level',
                              style: const TextStyle(color: Colors.white)),
                          Text('生存: $survivalSeconds 秒',
                              style: const TextStyle(color: Colors.white)),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Column(children: [
                          Text('火:$fireStones 冰:$iceStones',
                              style: const TextStyle(color: Colors.white)),
                          Text('雷:$thunderStones 回:$healStones',
                              style: const TextStyle(color: Colors.white)),
                        ])),
                  ],
                ),
              ),
              // 第一個 Row 區塊（HP, AP 等）結束後加入：
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('玩家 ATB',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: playerATB,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.cyanAccent),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('敵人 ATB',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: enemyATB,
                            backgroundColor: Colors.white30,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.redAccent),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (warningMessage.isNotEmpty)
                Text(warningMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18)),
              if (showDamage)
                Text(damageText,
                    style: TextStyle(
                        color: damageColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(enemyName,
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white)),
                      Image.asset('images/$enemyImage', width: 100),
                      Text('HP: $enemyHP',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 20),
                      Image.asset('images/hero.png', width: 100),
                      const Text('你', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

              if (canAct) _buildActionMenu(),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    if (showSkillMenu) {
      return Column(
        children: [
          ElevatedButton(
              onPressed: () => _useSkill('thrust'),
              child: const Text('突刺(10 AP)')),
          ElevatedButton(
              onPressed: () => _useSkill('slash'),
              child: const Text('斬擊(35 AP)')),
          ElevatedButton(
              onPressed: () => _useSkill('strike'),
              child: const Text('重擊+流血(25 AP)')),
          ElevatedButton(
              onPressed: () => setState(() {
                    showSkillMenu = false;
                    showMainMenu = true;
                  }),
              child: const Text('返回')),
        ],
      );
    } else if (showMagicMenu) {
      return Column(
        children: [
          ElevatedButton(
              onPressed: () => _useMagic('fire'), child: const Text('火焰魔法')),
          ElevatedButton(
              onPressed: () => _useMagic('ice'), child: const Text('冰結魔法')),
          ElevatedButton(
              onPressed: () => _useMagic('thunder'), child: const Text('雷電魔法')),
          ElevatedButton(
              onPressed: () => _useMagic('heal'), child: const Text('回復魔法')),
          ElevatedButton(
              onPressed: () => setState(() {
                    showMagicMenu = false;
                    showMainMenu = true;
                  }),
              child: const Text('返回')),
        ],
      );
    } else if (showMainMenu) {
      return Column(
        children: [
          ElevatedButton(
              onPressed: () => _playerAttack(), child: const Text('普通攻擊')),
          ElevatedButton(
              onPressed: () => setState(() {
                    showSkillMenu = true;
                    showMainMenu = false;
                  }),
              child: const Text('技能')),
          ElevatedButton(
              onPressed: () => setState(() {
                    showMagicMenu = true;
                    showMainMenu = false;
                  }),
              child: const Text('魔法')),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
