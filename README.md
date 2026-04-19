# 🏘️ Live Village

**Live Village** is an autonomous, 2D pixel-art social simulation built in **Godot 4**. The project creates a persistent "living petri dish" where LLM-powered NPCs live, work, trade, and build modular structures. The simulation is designed specifically for livestreams, allowing viewers to influence the world as "Environmental Deities" or "Village Patrons."

---

## 🕹️ Project Concept
The village operates on a **Deterministic State Machine**. NPCs are not controlled by the player; they are autonomous agents that use Large Language Models (LLMs) to reason through their survival needs, social interactions, and economic trades. 

The core experience revolves around **Emergent Narrative**: watching a community grow, fail, or thrive based on the combined logic of AI agents and the chaotic input of a live audience.

---

## 🧠 Core Systems

### 🏗️ Staged Construction
Buildings are constructed through a logical dependency tree rather than manual voxel placement:
* **Blueprint:** NPCs or the "Deity" (Viewer) select a plot.
* **Foundation:** Requires Stone/Wood; defines the building's footprint.
* **Framing & Walls:** Built component-by-component; blocks pathfinding once placed.
* **Roofing:** Final stage that toggles "Habitable" status, protecting inhabitants from weather-based stat drains (cold, wetness).

### 🎣 Autonomous Industry & Trade
* **Survival Loops:** NPCs independently prioritize tasks: **Farming** (Long-term food), **Fishing** (Steady supply), or **Hunting** (High-yield/High-risk).
* **LLM-Based Economy:** NPCs evaluate their own inventory scarcity. A starving builder may trade wood for fish at a loss, while a wealthy farmer might "hire" a hunter for protection or luxury goods.

### 👥 The "Patron" System (Viewer Interaction)
The project explores an ambiguous relationship between viewers and NPCs. A viewer may interact via:
* **The Avatar (Soul-Link):** Claiming an NPC directly (`!join`). The NPC bears their name and a personality seeded by the viewer.
* **The Familiar (Slime/Wisp):** An immortal entity representing a viewer that "adopts" a villager to buff their stats or collect "Rent/Essence."
* **The Landlord:** Owning the property/land where NPCs live, collecting resources as taxes to fund global "God Actions."

### 🧬 Genetics & Legacy
* **Inheritance:** Offspring inherit physical color palettes and "Genotype" stats (Speed, Metabolism, Social Intelligence).
* **Persistence:** If a viewer-linked NPC dies, their legacy/wealth can transfer to a descendant, ensuring long-term viewer retention.

---

## 🛠️ Technical Stack
* **Engine:** Godot 4.x (CharacterBody2D, TileMap, Custom Resources).
* **AI:** Local LLM Inference (Ollama/Llama-3) or OpenAI API.
* **Integrations:** WebSocket listeners for Twitch/TikTok Chat and Event Subscriptions.
* **Logic:** Component-based architecture for NPC brains and construction dependencies.

---

## 🛤️ Roadmap Tracker

| Phase | Milestone | Status |
| :--- | :--- | :--- |
| **Phase 0** | **Planning & Architecture:** Staged building logic, LLM context mapping, and Patron-model definition. | 🟡 **CURRENT** |
| **Phase 1** | **The Foundation (MVP):** Basic 2D world, NPC movement, Hunger/Energy stats, and `!join` command. | ⚪ PENDING |
| **Phase 2** | **Industry & Economy:** Staged construction implementation, Farming/Fishing/Hunting loops, and Inventory. | ⚪ PENDING |
| **Phase 3** | **The Brain (LLM):** Context-injection for decisions, social dialogue bubbles, and persistent memory. | ⚪ PENDING |
| **Phase 4** | **Growth & Legacy:** Genetics, aging, reproduction cycles, and "Patron/Slime" persistence systems. | ⚪ PENDING |
| **Phase 5** | **Chaos & Weather:** Dynamic weather, natural disasters (Fire/Lightning), and premium viewer triggers. | ⚪ PENDING |

---

**"Build the village. Watch the drama. Trigger the storm."**
