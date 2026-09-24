# Mini Militia 2D Arena Shooter (Flutter Web & Mobile)

A high-performance 2D multiplayer side-view arena shooter inspired by the classic combat gameplay of **Mini Militia**, built using **Flutter**, **Flame Engine**, and designed **Mobile-Landscape-First** for touchscreens, tablets, and desktop browsers.

---

## 1. Prerequisites & Environment

* **Flutter SDK**: 3.29.3 (Channel unknown / stable)
* **Dart SDK**: ^3.7.2
* **Flame Game Engine**: ^1.30.1
* **Supported Platforms**:
  * Flutter Web (Chrome, Safari, Firefox, Edge, Mobile Web)
  * Mobile (Android / iOS)
  * Desktop (macOS / Linux / Windows)

---

## 2. Installation & Setup

1. **Clone or navigate to the project directory**:
   ```bash
   cd Team_B_flutter
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify analyzer passes cleanly**:
   ```bash
   flutter analyze
   ```

4. **Run unit & widget smoke tests**:
   ```bash
   flutter test
   ```

---

## 3. How to Run the Game

### Running on Flutter Web (Local Dev Server)
```bash
flutter run -d chrome
```

### Running on a Specific Local Port (e.g., 8080)
```bash
flutter run -d chrome --web-port=8080
```

### Building the Release Web Bundle
```bash
flutter build web --release
```
The compiled output is located in `build/web/` and can be hosted on any static web host or CDN (e.g., Nginx, GitHub Pages, Cloudflare Pages, S3).

---

## 4. Controls Guide

### Mobile / Touch Controls (Primary)
The game is built primarily for mobile landscape gameplay with oversized, semi-transparent touch controls:
* **Movement**: Virtual Joystick on the **bottom-left** (drag left or right).
* **Aiming**: Touch and drag on the **right half of the screen** to swivel the 360° aim angle with reticle feedback.
* **Jump**: Large green button on the **bottom-right** (tap to leap across platforms).
* **Fire / Shoot**: Large red button on the **bottom-right** (press or **hold** for continuous automatic fire).
* **Pause / Settings**: Button in the **top-right** of the HUD to adjust camera zoom or exit.

### Desktop Controls (Development & Testing)
* `A` or `Left Arrow`: Move Left
* `D` or `Right Arrow`: Move Right
* `W`, `Space`, or `Up Arrow`: Jump
* **Mouse Move / Hover**: 360° Aim towards mouse cursor
* **Mouse Left Click / Hold**: Shoot weapon in aimed direction

---

## 5. Mobile-Landscape-First Design & Orientation Handling

* **Target Aspect Ratios**: Optimized for `16:9`, with full adaptive support for ultra-wide mobile ratios (`18:9`, `19.5:9`, `20:9`), tablets, and desktops.
* **Portrait Orientation Protection**: If a mobile phone or browser window enters portrait mode (`height > width`), an automatic screen overlay appears:
  > **"PLEASE ROTATE YOUR DEVICE"**  
  > *Mini Militia Arena is designed for Mobile Landscape gameplay.*
* The game automatically restores gameplay once the device returns to landscape orientation.
* Camera zoom is fully configurable in [game_camera.dart](file:///Users/nishanth/Desktop/arun/Team_B_flutter/lib/game/camera/game_camera.dart) and in the in-game Pause menu.

---

## 6. Character Face System & Replacing PNGs

### How It Works:
* Exactly **10 hardcoded character slots** (`Character 1` through `Character 10`) are registered in [character_registry.dart](file:///Users/nishanth/Desktop/arun/Team_B_flutter/lib/characters/character_registry.dart).
* **Shared Body & Animations**: All 10 characters share the exact same tactical soldier body, physics, and animations (`IDLE`, `RUN`, `JUMP`, `FALL`, `SHOOT`, `DEATH`).
* **Modular Head Socket**: The face is **never merged permanently into the body sprite**. Instead, it is loaded as an independent PNG overlay anchored directly to the soldier's head pivot.

### How to Replace the Face Images:
To replace the placeholder faces with real production PNG artwork, simply overwrite the PNG files in:
```
assets/
  characters/
    face_01.png
    face_02.png
    face_03.png
    face_04.png
    face_05.png
    face_06.png
    face_07.png
    face_08.png
    face_09.png
    face_10.png
```
* **Recommended PNG specs**: 128x128 px, transparent background, centered head/face.
* **Zero Dart Code Changes Required**: The registry and player components automatically load whatever PNG files are located in that folder.

---

## 7. Project Architecture

```
lib/
├── main.dart                          # App entry point, orientation lock & theme
├── characters/
│   ├── character_definition.dart      # Character model (id, name, faceAsset, callsign)
│   └── character_registry.dart        # 10 hardcoded character slot definitions
├── multiplayer/
│   ├── player_state.dart              # Synchronizable network model & event schemas
│   ├── multiplayer_client.dart        # Abstract network client interface
│   └── mock_multiplayer_client.dart   # Local bot simulation & simulated network ticks
├── controls/
│   ├── input_controller.dart          # Central bridge between UI and Flame physics
│   ├── virtual_joystick.dart          # Custom semi-transparent movement joystick
│   └── mobile_controls.dart           # Touch overlay (Aim zone, Joystick, Jump, Shoot)
├── game/
│   ├── mini_militia_game.dart         # Main FlameGame instance & world coordinator
│   ├── camera/
│   │   └── game_camera.dart           # Configurable camera zoom & viewport clamp
│   ├── components/
│   │   ├── player.dart                # Modular Player (BODY, FACE, WEAPON)
│   │   ├── bullet.dart                # Projectile entity with tracer effects
│   │   ├── weapon.dart                # Fire rate, spread, muzzle offset & cooldown
│   │   └── platform.dart              # Solid ground, floating ledges, boundary walls
│   ├── systems/
│   │   ├── collision_system.dart      # Gravity, AABB platform & bullet collision
│   │   └── combat_system.dart         # Damage calculation, bullet lifecycle & scoring
│   └── world/
│       └── arena.dart                 # Arena layout, floating platforms & spawn points
├── screens/
│   ├── lobby_screen.dart              # 10-character selection & bot count configuration
│   └── game_screen.dart               # Flame GameWidget container with HUD & inputs
└── ui/
    ├── hud.dart                       # Top tactical HUD (Health, Kills, Deaths, Pause)
    ├── health_bar.dart                # High-tech glowing segmented health bar
    └── orientation_overlay.dart       # "Please rotate your device" portrait shield
```

---

## 8. Multiplayer Architecture & WebSocket Relay

The game features dual multiplayer modes:
1. **🤖 Solo Practice (Bots)**:
   * Powered by [MockMultiplayerClient](file:///Users/nishanth/Desktop/arun/Team_B_flutter/lib/multiplayer/mock_multiplayer_client.dart).
   * Spawns autonomous combat bots with jetpack flight, 360° aiming, and platform traversal for offline training.
2. **🌐 Online Multiplayer**:
   * Powered by [WebSocketMultiplayerClient](file:///Users/nishanth/Desktop/arun/Team_B_flutter/lib/multiplayer/websocket_multiplayer_client.dart) connecting to [server/bin/server.dart](file:///Users/nishanth/Desktop/arun/Team_B_flutter/server/bin/server.dart).
   * Supports rooms up to 10 players, synchronized jetpack flight, 360° fire, and damage.

---

## 9. Deploying to GitHub & Playing Online Multiplayer

### Part A: Deploy Frontend to GitHub Pages (Automated via GitHub Actions)

The repository includes a ready-to-run GitHub Actions workflow in `.github/workflows/deploy.yml`.

1. **Initialize Git and Push to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit with Mini Militia 2D arena game"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
   git push -u origin main
   ```

2. **Enable GitHub Pages in Repo Settings**:
   * On GitHub, go to **Settings** → **Pages**.
   * Under **Build and deployment** → **Source**, select **GitHub Actions**.
   * Your game will automatically build and publish to:
     ```
     https://<YOUR_USERNAME>.github.io/<YOUR_REPO_NAME>/
     ```

---

### Part B: Hosting the WebSocket Multiplayer Server (Free Tier)

> **Important**: GitHub Pages is a static host (it serves HTML/JS/CSS) and cannot run background WebSocket server processes. Additionally, browsers block insecure `ws://` connections from `https://` websites (Mixed Content Security). You need a secure `wss://` endpoint for multiplayer on GitHub Pages.

Choose any of the following 100% free options:

#### Option 1: Free Cloud Deploy on Render.com (Recommended)
1. Fork or push this repository to GitHub.
2. Go to [Render.com](https://render.com) (free account) and click **New +** → **Web Service**.
3. Select your repository.
4. Render automatically detects the [server/Dockerfile](file:///Users/nishanth/Desktop/arun/Team_B_flutter/server/Dockerfile).
5. Set:
   * **Name**: `mini-militia-server`
   * **Instance Type**: **Free**
6. Click **Create Web Service**.
7. Render gives you an address like `https://mini-militia-server.onrender.com`.
8. Your secure WebSocket URL is:
   ```
   wss://mini-militia-server.onrender.com
   ```
9. When joining multiplayer on GitHub Pages, enter this URL into the **Server URL** field!

#### Option 2: Free Instant Tunnel for Friends (Cloudflare Tunnel or Ngrok)
To play with friends right from your local machine:
1. Run the local server:
   ```bash
   dart run server/bin/server.dart
   ```
2. In a second terminal, run `cloudflared` (or `ngrok`):
   ```bash
   cloudflared tunnel --url http://localhost:8081
   ```
3. Cloudflare gives you a free HTTPS/WSS URL (e.g., `wss://random-subdomain.trycloudflare.com`).
4. Share that URL with your friends to paste into the in-game **Server URL** input!
