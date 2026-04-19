# 🏘️ Live Village

**Live Village** is an autonomous, 2D pixel-art social simulation built in **Godot 4**. The project creates a persistent "living petri dish" where LLM-powered NPCs live, work, trade, and build, while being directly influenced by a live audience on Twitch or TikTok.

---

## 🕹️ Project Concept
The simulation runs autonomously with NPCs making logic-based decisions for survival and growth. Viewers act as "Environmental Deities," using chat commands and donations to either assist the village (feeding, healing) or introduce chaos (natural disasters, curses).

---

## 🧠 Core Systems

### 🏗️ Staged Construction
To avoid the complexity of voxel-by-voxel building, structures follow a **Dependency-Based Construction** model:
* **Foundation:** NPCs claim a plot and clear the land.
* **Framing & Walls:** Requires gathered wood/stone; physically blocks paths.
* **Roofing:** Finalizes the structure, enabling "Habitable" status (protects NPCs from cold/rain stat drains).

### 🎣 Autonomous Industry
NPCs operate on a priority-based state machine influenced by their LLM "Brain":
* **Farming:** Sustainable carbohydrate production.
* **Fishing/Hunting:** High-protein resource gathering.
* **Trading:** NPCs evaluate inventory scarcity and use LLM reasoning to negotiate trades with neighbors.

### 🧬 Genetics & Growth
* **Inheritance:** Offspring inherit physical traits (color palettes) and internal stats (metabolism, speed, intelligence).
* **Legacy:** When a viewer-linked NPC has a child, that child can be "inherited" by the viewer, creating long-term chat dynasties.

### 💬 LLM-Driven Narrative
Each NPC processes their current environment (Health, Hunger, Inventory, Nearby NPCs) through an LLM to generate:
* Real-time chat bubble dialogue.
* Social opinions (Friendships vs. Grudges).
* Economic motivations (Choosing to work, steal, or trade).

---

## 🛠️ Technical Stack
* **Game Engine:** Godot 4.x (using `CharacterBody2D` and `TileMap`).
* **AI Orchestration:** Local LLM (Ollama) or OpenAI API for decision-making and dialogue.
* **Integration:** WebSocket listeners for real-time Twitch/TikTok chat parsing.
* **Architecture:** Component-based logic for NPC behaviors and building requirements.

---

## 🛤️ Roadmap Tracker

- [x] **Phase 0: Planning & Architecture** 📝
    - [x] Concept definition.
    - [x] Staged building logic design.
    - [ ] NPC State Machine mapping.
    - [ ] Twitch/TikTok API hookup strategy.

- [ ] **Phase 1: The Foundation (MVP)** 🏗️
    - [ ] Basic 2D Top-Down environment.
    - [ ] NPC movement and Hunger/Energy stats.
    - [ ] WebSocket integration for `!join` command.

- [ ] **Phase 2: Industry & Economy** 🌲
    - [ ] Staged Construction system (Foundation -> Walls -> Roof).
    - [ ] Farming, Fishing, and Hunting loops.
    - [ ] Basic autonomous trading logic.

- [ ] **Phase 3: The Brain (LLM)** 🧠
    - [ ] Context-injection for NPC decision making.
    - [ ] Real-time speech bubble generation.
    - [ ] Persistent NPC memory and relationship tracking.

- [ ] **Phase 4: Growth & Legacy** 🧬
    - [ ] Genetics and inheritance system.
    - [ ] Aging and reproduction cycles.
    - [ ] Family tree UI for viewers.

- [ ] **Phase 5: Chaos & Weather** ⚡
    - [ ] Dynamic weather system (Rain/Snow/Heatwave).
    - [ ] Natural disasters (Lightning, Fire, Tornadoes).
    - [ ] High-tier viewer interaction triggers.
    - [ ] 
