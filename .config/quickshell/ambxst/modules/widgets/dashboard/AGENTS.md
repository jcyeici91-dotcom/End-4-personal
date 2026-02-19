# DASHBOARD KNOWLEDGE BASE

## OVERVIEW
The Dashboard is the central interactive hub of Ambxst, providing a unified interface for widgets, system controls, media, and AI tools. It uses a high-performance, lazy-loaded tab architecture with LRU-based memory management.

## STRUCTURE
- **Side Tabs**: Vertical navigation bar on the left for switching main views.
- **WidgetsTab**: Main grid containing `FullPlayer`, `Calendar`, `NotificationHistory`, and quick system toggles.
- **System Controls**: Vertical column on the right with brightness sliders and circular volume/mic controls.
- **Lazy Loaders**: `TabLoader` (internal to `Dashboard.qml`) handles on-demand loading and eviction of tabs.

## WHERE TO LOOK
| Component | Location | Role |
|-----------|----------|------|
| `Dashboard` | `Dashboard.qml` | Root orchestrator; handles LRU logic, layout, and animations. |
| `WidgetsTab` | `widgets/WidgetsTab.qml` | Main container for the "hub" experience. |
| `Controls` | `controls/` | Directory for specific setting panels (Wifi, Audio, Bluetooth). |
| `Assistant` | `assistant/AssistantTab.qml` | Interface for the AI service. |
| `Metrics` | `metrics/MetricsTab.qml` | Real-time system resource monitoring. |

## CONVENTIONS
- **LRU Management**: Tabs are evicted from memory based on usage. Use `shouldTabBeLoaded(index)` for conditional visibility.
- **Keyboard Flow**: Components should implement `focusSearchInput()` to allow the root to forward focus immediately upon opening.
- **UI Primitives**: ALWAYS use `StyledRect` variants (`pane`, `internalbg`, `focus`) for containers to ensure theme consistency.
- **Service Bindings**: Connect directly to Service Singletons (e.g., `NetworkService`, `Audio`) for state; avoid prop-drilling.
