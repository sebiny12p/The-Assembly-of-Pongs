# 🏓 The Assembly of Pongs

Classic Pong rebuilt from scratch in 100% pure 32-bit RISC Assembly. Featuring real-time player controls, an autonomous AI opponent, paddle physics, and hardware-level memory-mapped graphics.

![Language](https://img.shields.io/badge/Language-Assembly_(SCAT_RISC)-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-von_Neumann_32--bit-orange.svg)
![Display](https://img.shields.io/badge/Display-80x60_VRAM_MMIO-brightgreen.svg)

---

## 🎮 Features
* **Human Player (Left Paddle - Cyan)**: Controlled in real time via keyboard (`W` / `S` or `Up` / `Down` arrow keys).
* **AI Bot Opponent (Right Paddle - Magenta)**: Autonomous tracking agent that follows the ball's vertical trajectory in real time.
* **Physics & Collisions**: Ball bounces off the top/bottom boundaries and deflects off paddles upon contact.
* **Score & Reset**: Missing a paddle resets the ball to the center and serves toward the scoring player.
* **Hardware-Level Graphics**: Uses memory-mapped framebuffers (`0xB0000000`) and MMIO input (`0xC0000000`).

---

## 🏗️ Architecture & Technical Highlights
* **Target Architecture**: SCAT (a pedagogical 32-bit RISC architecture closely modeled after ARM and RISC-V).
* **Memory-Mapped Video (VRAM)**: Base address `0xB0000000` with an $80 \times 60$ framebuffer layout ($4 \times (y \times 80 + x)$).
* **Memory-Mapped Input (MMIO)**: Keyboard input controller polled at `0xC0000000`.
* **Execution Stack & Calling Convention**: Implements leaf/non-leaf calling conventions with Link Register (`LR` = `R14`) and Stack Pointer (`SP` = `R13`).
* **Frame Regulation**: Custom busy-wait cycle burning subroutine to achieve smooth ~30-45 FPS animation.

---

## 🚀 How to Run

### 1. Prerequisites
* Python 3.8+
* Tkinter (included with standard Python on Windows/Mac/Linux)

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
   screen
   continue
   ```
2. Click on the popup **Scat** window.
3. Use **`W` / `S`** or **`Up` / `Down` Arrow Keys** to move your paddle!
