# 🏓 The Assembly of Pongs

Classic Pong rebuilt from scratch in 100% pure 32-bit RISC Assembly. Featuring real-time player controls, 4 selectable AI difficulty modes, dynamic rally acceleration, instant match restarts, win/loss fail states, and flicker-free 60 FPS delta-rendering.

![Language](https://img.shields.io/badge/Language-Assembly_(SCAT_RISC)-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-von_Neumann_32--bit-orange.svg)
![Display](https://img.shields.io/badge/Display-80x60_VRAM_MMIO-brightgreen.svg)

---

## 🎮 Features
* **Human Player (Left Paddle - Cyan)**: Controlled in real time via keyboard (`W` / `S` or `Up` / `Down` arrow keys).
* **AI Bot Opponent (Right Paddle - Magenta)**: 4 selectable difficulty levels with realistic reaction windows and speed caps.
* **4 AI Difficulty Levels**:
  * **1 (Easy)**: Sluggish bot, narrow reaction zone ($x \ge 52$), relaxed ball speed.
  * **2 (Normal)**: Balanced AI, half-court tracking ($x \ge 35$), moderate pace.
  * **3 (Hard)**: Fast bot, full-court tracking ($x \ge 15$), intense pace.
  * **4 (Very Hard - Dynamic)**: Full tracking + **dynamic speed acceleration** that gets faster with every single rally!
* **Instant Match Restart**: Press `R` or `Space` anytime during play or after game over to instantly restart.
* **Win & Fail States**:
  * **Player Loss**: Screen border turns **RED** (`0xFF000000`).
  * **Player Win**: Screen border turns **GREEN** (`0x00FF0000`).
* **Visual HUD**: The top border displays live difficulty indicators (1 to 4 colored dots).
* **Ultra-Smooth 60 FPS Delta-Rendering**: Instead of redrawing entire paddles every frame, only the paddle ends (1 pixel on, 1 pixel off) are updated, eliminating line flicker.

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
* **Memory-Mapped Input (MMIO)**: Keyboard controller polled at `0xC0000000`.
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
2. The **Scat** window pops up automatically!
3. Click on the game window and use `W`/`S` or `Up`/`Down` to play! Press `1`-`4` to set difficulty, or `R` to restart.
