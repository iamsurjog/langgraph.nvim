# langGraphVisualizer.nvim

A lightweight, high-performance Neovim plugin that generates **real-time, interactive graph visualizations** of your LangGraph workflows directly in your default browser.

## 🚀 Installation

Using **Lazy.nvim**:

```lua
{
    "your-github-username/langGraphVisualizer.nvim",
    config = function()
        require("langGraphVisualizer").setup()
    end
}
```
using **using vim.pack**:

```lua
vim.pack.add({ "https://github.com/iamsurjog/langgraph.nvim" })
```

### Prerequisites

Before running the commands, ensure you have the server dependencies installed. Navigate to the plugin's server directory and install the WebSocket library:

```bash
cd ~/.local/share/nvim/lazy/langGraphVisualizer.nvim/server
npm install ws

```

---

## 🛠️ Commands

The plugin exposes two primary user commands:

| Command | Action |
| --- | --- |
| `:LangGraphOpen` | Lazily triggers the background process (if not running) and launches the visualizer canvas in your default web browser. |
| `:LangGraphRender` | Parses your active buffer code structure instantly and updates the layout on your browser canvas. |

---

## 💡 Code Syntax Support

The plugin's parsing layout engine detects the following standard LangGraph paradigms out of the box:

```python
# 1. Entry point maps to a distinct START node
workflow.set_entry_point("agent")

# 2. Standard processing nodes (supports single/double quotes & multiline formatting)
workflow.add_node("agent", call_model)
workflow.add_node(tool_executor) 

# 3. Directed edges
workflow.add_edge("agent", "tool_executor")

# 4. Conditional Edges map labeled routing vectors automatically
workflow.add_conditional_edges(
    "tool_executor",
    should_continue,
    {
        "continue": "agent",
        "end": END
    }
)

```

---

## 🎨 Layout Styling Definitions

The visualizer transforms Python configurations into high-contrast, recognizable components:

* 🔵 **Blue Ellipse (`START`):** Automatically maps to the node indicated in your `.set_entry_point()` directive.
* 🟢 **Green Rectangle:** Processing agent or tool execution blocks.
* 🔴 **Red Ellipse (`END`):** Terminal endpoints in the graph lifecycle loop.
* ➡️ **Solid Blue Arrow:** Direct structural workflow state progressions.
* ↩️ **Dashed Yellow Arrow:** Conditional paths, cleanly labeled with the mapped router function keys directly on the vector line.

---

## 🛡️ Architecture & Network Troubleshooting

The plugin isolates communication to the local loopback interface to prevent collisions. Neovim communicates to a local process using standard I/O channels (`stdin`/`stdout`), which then maps data straight to the browser on a fixed IPv4 loopback socket: `ws://127.0.0.1:8055`.

If a ghost process accidentally hangs onto the port after a hard crash, you can force-clear it via your terminal:

```bash
fuser -k 8055/tcp

```

*(Neovim will automatically handle process lifecycles under normal operation when exiting standard sessions).*
