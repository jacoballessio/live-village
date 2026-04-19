# 🏘️ Live Village: Autonomous Agent Village

**Live Village** is an autonomous, 2D pixel-art village simulation built in **Godot 4**. It features LLM-driven NPCs who live, trade, and build modular structures in a world influenced by livestream viewers.

---

## 🏗️ Architectural Philosophy
The village is a **State-Driven Simulation**. NPCs are not puppeteered; they are autonomous agents that interact with a world governed by strict logical constraints (e.g., roofs require walls, hunger requires farming).

---

## 🧠 Core Systems

### 1. Modular Staged Construction
Buildings are constructed in logical phases rather than block-by-block voxels:
* **Blueprint Placement:** NPCs select a site based on proximity to resources.
* **Dependency Tree:** Construction follows a strict hierarchy: `Foundation -> Framing -> Walls -> Roof`.
* **Material Logistics:** NPCs must hunt, fish, or mine to gather specific materials required for the current stage.

### 2. Autonomous Economic Loop
* **Specialized Roles:** NPCs develop "Skills" (Farming, Fishing, Hunting, Building).
* **The Trade Engine:** NPCs use LLM reasoning to value items. *Ex: A starving Hunter might trade a rare pelt for three fish.*
* **Shared Inventory:** The village has "Public Piles" and "Private Chests." Conflict can arise if an NPC "steals" from the public supply.

### 3. LLM "Brain" Integration
Each NPC has a persistent memory and personality:
* **Context Injection:** The game feeds the LLM a JSON string of local variables (Health, Inventory, Nearby NPCs).
* **Natural Socializing:** Dialogue is generated in real-time. NPCs can form "Friendships" or "Grudges" that affect trade prices and building cooperation.

### 4. Interactive Deity (Twitch/TikTok)
* **Direct Interaction:** `!join` to spawn an NPC; `!feed` to assist.
* **Chaotic Events:** Viewers pay to trigger Natural Disasters (Lightning, Fire, Tornado) which can damage specific "Stages" of a building.
* **Genetics:** Offspring inherit the speed, metabolism, and color-palettes of their parents.

---

## 🛠️ Technical Stack
* **Engine:** Godot 4.x (using `CharacterBody2D` and `TileMap`).
* **AI Inference:** Local LLM (Ollama) or OpenAI API for high-level decision making.
* **Dependency Logic:** Custom Resource-based Building System.
* **Networking:** WebSocket connection for real-time Twitch/TikTok chat parsing.

---

## 🚦 Construction Workflow (Logic)
1.  **Validation:** `check_constraints(building_part)`
2.  **Resource Check:** `has_materials(part.cost)`
3.  **Labor:** `perform_action(build_time)`
4.  **State Update:** `notify_llm("I finished the walls of my house.")`
5.  
