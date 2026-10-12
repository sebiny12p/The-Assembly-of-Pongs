# 🏓 The Assembly of Pongs

Classic Pong rebuilt from scratch in 100% pure 32-bit RISC Assembly. Featuring a First-to-3 championship system, paddle spin & aiming physics, minimalist LED HUD, 4 AI difficulty levels, dynamic rally acceleration, and flicker-free 60 FPS delta-rendering.

![Language](https://img.shields.io/badge/Language-Assembly_(SCAT_RISC)-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-von_Neumann_32--bit-orange.svg)
![Display](https://img.shields.io/badge/Display-80x60_VRAM_MMIO-brightgreen.svg)

---

## 🎮 Features
* **Championship Match System (First to 3 Points)**:
  * Each point scored triggers a victory/loss flash before the ball re-serves.
  * The first player to score 3 points wins the match!
* **Paddle Aiming & Spin Physics**:
  * **Top 3 Pixels**: Deflects at a sharp upward angle ($dy = -1$).
  * **Middle 4 Pixels**: Laser-straight horizontal drive ($dy = 0$).
  * **Bottom 3 Pixels**: Deflects at a sharp downward angle ($dy = +1$).
* **Minimalist Top-Border LED HUD (Zero Clutter)**:
  * Top border embeds discreet LED indicators:
    * Left ($x=10, 12, 14$): 3 Cyan score LEDs for Player 1.
    * Center ($x=37, 39, 41, 43$): 1–4 difficulty dots.
    * Right ($x=65, 67, 69$): 3 Magenta score LEDs for AI Bot.
  * The court itself remains 100% clean and unobstructed black!
* **4 AI Difficulty Levels**:
  * **1 (Easy)**: Sluggish bot, narrow reaction zone ($x \ge 52$), relaxed pace.
  * **2 (Normal)**: Balanced AI, half-court tracking ($x \ge 35$), moderate pace.
  * **3 (Hard)**: Fast bot, full-court tracking ($x \ge 15$), intense pace.
  * **4 (Very Hard - Dynamic)**: Full tracking + **dynamic speed acceleration** that gets faster with every rally!
* **Instant Match Restart**: Press `R` or `Space` anytime during play or on game over to reset the match.
* **Win & Fail States**:
  * **Match Lost**: Border flashes **RED** (`0xFF000000`).
  * **Match Won**: Border flashes **GREEN** (`0x00FF0000`).
* **Ultra-Smooth 60 FPS Delta-Rendering**: Only paddle ends are rewritten (1 pixel on, 1 pixel off), eliminating screen flicker.

---

## 🕹️ Controls

| Action | Key(s) |
| :--- | :--- |
| **Move Up** | `W` or `Up Arrow` |
| **Move Down** | `S` or `Down Arrow` |
| **Restart Match** | `R` or `Space` |
| **Select Easy Mode** | `1` |
| **Select Normal Mode** | `2` |
| **Select Hard Mode** | `3` |
| **Select Very Hard Mode** | `4` |

---

## 🏗️ Architecture & Technical Highlights
* **Target Architecture**: SCAT (a pedagogical 32-bit RISC architecture closely modeled after ARM and RISC-V).
* **Memory-Mapped Video (VRAM)**: Base address `0xB0000000` with an $80 \times 60$ framebuffer layout ($4 \times (y \times 80 + x)$).
* **Memory-Mapped Input (MMIO)**: Polled at `0xC0000000`.
* **Execution Stack & Calling Convention**: Implements leaf/non-leaf calling conventions with Link Register (`LR` = `R14`) and Stack Pointer (`SP` = `R13`).
* **Delta-Rendering Engine**: Cuts VRAM write operations by ~90%, ensuring smooth motion without display artifacts.

---

## 🚀 How to Run

### 1. Prerequisites
* Python 3.8+
* Tkinter (included by default with standard Python on Windows/Mac/Linux)

### 2. Assemble the Game
```powershell
python scat/asm.py pong.asm
```

### 3. Launch the Simulator
```powershell
python scat/sim.py pong.scat
```

### 4. Play
1. In the simulator terminal prompt `(sim)`, type:
   ```text
   continue
   ```
   *(or simply `c`)*
2. The game window pops up automatically!
3. Click on the game window and use `W`/`S` or `Up`/`Down` to aim and score!
