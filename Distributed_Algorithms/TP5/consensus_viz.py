import sys
import math
import threading
from PyQt6.QtWidgets import (QApplication, QMainWindow, QGraphicsScene, 
                             QGraphicsView, QGraphicsEllipseItem, QGraphicsLineItem, 
                             QGraphicsTextItem, QVBoxLayout, QWidget, QGraphicsItem)
from PyQt6.QtCore import QTimer, Qt, QPointF, QRectF, pyqtSignal
from PyQt6.QtGui import QBrush, QPen, QColor, QFont

# Import your simulation logic
import snowflake

# --- Configuration ---
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
NODE_RADIUS = 40
SCENE_RADIUS = 200  # How spread out the nodes are
REFRESH_RATE_MS = 100  # Update UI every 100ms

# --- Colors ---
COLOR_BLUE = QColor("#3498db")  # Light Blue
COLOR_RED = QColor("#e74c3c")   # Red
COLOR_DECIDED = QColor("#2ecc71") # Green (Visual cue for 'Decided')
COLOR_DEFAULT = QColor("#95a5a6") # Grey

class VisualNode(QGraphicsEllipseItem):
    """
    A graphic item representing a single Snowflake Node.
    It draws the circle and manages its own text label.
    """
    def __init__(self, x, y, radius, node_logic, main_window=None, idx=None):
        super().__init__(-radius, -radius, radius * 2, radius * 2)
        self.node_logic = node_logic  # Reference to the actual snowflake.Node object
        self.main_window = main_window
        self.idx = idx
        self.setPos(x, y)
        
        # Visual styling
        self.setPen(QPen(Qt.GlobalColor.black, 2))
        self.setBrush(QBrush(COLOR_DEFAULT))
        
        # Flags for interaction (for your "Later" requirements)
        self.setFlag(QGraphicsItem.GraphicsItemFlag.ItemIsMovable)
        self.setFlag(QGraphicsItem.GraphicsItemFlag.ItemIsSelectable)
        self.setAcceptHoverEvents(True)

        # Create the text label (ID and State)
        self.text_item = QGraphicsTextItem(self)
        self.update_label_text()
        self.center_text()

    def center_text(self):
        # Center the text inside the circle
        rect = self.text_item.boundingRect()
        self.text_item.setPos(-rect.width() / 2, -rect.height() / 2)

    def update_label_text(self):
        # Safe read of thread-locked variables
        state_txt = "UNK"
        count = 0
        decided = False
        
        # We assume the logic object has locks, but for simple visualization reading 
        # atomic types like bool/int is often "safe enough" for display. 
        # To be strictly correct, we use the locks provided by your class.
        with self.node_logic.state_lock:
            state_txt = self.node_logic.state.value
        
        with self.node_logic.counter_lock:
            count = self.node_logic.counter
            
        with self.node_logic.decided_lock:
            decided = self.node_logic.decided

        # Update Text
        display_text = f"ID: {self.node_logic.id}\n{state_txt}\nConf: {count}"
        if decided:
            display_text += "\n[DECIDED]"
        
        self.text_item.setPlainText(display_text)
        self.text_item.setFont(QFont("Arial", 8, QFont.Weight.Bold))
        self.center_text()

        # Update Color based on State
        if decided:
            self.setPen(QPen(QColor("gold"), 5))
        else:
            self.setPen(QPen(Qt.GlobalColor.black, 2))
        if state_txt == "BLUE":
            self.setBrush(QBrush(COLOR_BLUE))
        elif state_txt == "RED":
            self.setBrush(QBrush(COLOR_RED))
        else:
            self.setBrush(QBrush(COLOR_DEFAULT))

    def mousePressEvent(self, event):
        # Only allow color change before simulation starts (before first step or auto-run)
        if self.main_window and self.main_window.allow_initial_color_change:
            # Toggle color
            with self.node_logic.state_lock:
                if self.node_logic.state.value == "BLUE":
                    self.node_logic.state = self.node_logic.state.__class__("RED")
                else:
                    self.node_logic.state = self.node_logic.state.__class__("BLUE")
            self.update_label_text()
        else:
            super().mousePressEvent(event)


from PyQt6.QtWidgets import QPushButton, QHBoxLayout, QLabel, QSpinBox, QCheckBox

class MainWindow(QMainWindow):
    query_arrow_signal = pyqtSignal(int, int)
    # For query visualization
    QUERY_HIGHLIGHT_COLOR = QColor("#f1c40f")
    QUERY_HIGHLIGHT_MS = 400
    def __init__(self):
        super().__init__()
        self.waiting_overlay = QLabel("Resetting... Please wait.")
        self.waiting_overlay.setStyleSheet("background: rgba(255,255,255,0.85); color: #333; font-size: 32px; font-weight: bold; border: 2px solid #888; border-radius: 10px; padding: 40px;")
        self.waiting_overlay.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.waiting_overlay.setVisible(False)
        self.waiting_overlay.setMargin(20)
        self.waiting_overlay.setMinimumSize(400, 100)
        self.waiting_overlay.setMaximumHeight(200)
        self.waiting_overlay.setWordWrap(True)
        # Will be parented to central widget after it's created
        self.setWindowTitle("Snowflake Consensus Visualization")
        self.resize(WINDOW_WIDTH, WINDOW_HEIGHT)

        # 1. Setup the Scene and View
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setRenderHint(self.view.renderHints().Antialiasing)

        # --- Controls ---
        self.step_button = QPushButton("Step")
        self.run_checkbox = QCheckBox("Auto-run")
        self.reset_button = QPushButton("Reset")
        self.timing_label = QLabel("Step Time (ms):")
        self.timing_spin = QSpinBox()
        self.timing_spin.setRange(10, 5000)
        self.timing_spin.setValue(REFRESH_RATE_MS)

        controls_layout = QHBoxLayout()
        controls_layout.addWidget(self.step_button)
        controls_layout.addWidget(self.run_checkbox)
        controls_layout.addWidget(self.reset_button)
        controls_layout.addWidget(self.timing_label)
        controls_layout.addWidget(self.timing_spin)
        controls_layout.addStretch()

        # Central widget layout
        layout = QVBoxLayout()
        layout.addLayout(controls_layout)
        layout.addWidget(self.view)
        central_widget = QWidget()
        central_widget.setLayout(layout)
        self.setCentralWidget(central_widget)
        # Parent overlay to central widget and cover the view
        self.waiting_overlay.setParent(central_widget)
        self.waiting_overlay.resize(central_widget.size())
        self.waiting_overlay.move(0, 0)

        # 2. Initialize the Simulation Data
        self.nodes_logic = []      # List of snowflake.Node objects
        self.visual_nodes = []     # List of VisualNode items
        self.threads = []          # Keep track of threads
        self._step_event = threading.Event()
        self._step_mode = True
        self._should_reset = False
        self.allow_initial_color_change = True
        self.edge_items = {}  # (src_idx, dst_idx): QGraphicsLineItem

        # Connect signal for thread-safe arrow drawing
        self.query_arrow_signal.connect(self._draw_query_arrow)
        self.setup_simulation()

        # 3. Start the GUI Update Loop
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_ui)
        self.timer.start(self.timing_spin.value())

        # --- Connect Controls ---
        self.step_button.clicked.connect(self.step_once)
        self.run_checkbox.stateChanged.connect(self.toggle_run_mode)
        self.timing_spin.valueChanged.connect(self.update_timer_interval)
        self.reset_button.clicked.connect(self.reset_simulation)

    def step_once(self):
        self.allow_initial_color_change = False
        self._step_event.set()

    def toggle_run_mode(self, state):
        self._step_mode = not self.run_checkbox.isChecked()
        if not self._step_mode:
            self.allow_initial_color_change = False
            self._step_event.set()  # Unblock if waiting

    def update_timer_interval(self, value):
        self.timer.setInterval(value)

    def reset_simulation(self):
        # Show waiting overlay and disable controls
        # Cover the central widget
        self.waiting_overlay.resize(self.centralWidget().size())
        self.waiting_overlay.move(0, self.window().height()//3)
        self.waiting_overlay.setVisible(True)
        self.waiting_overlay.raise_()
        self.step_button.setEnabled(False)
        self.run_checkbox.setEnabled(False)
        self.reset_button.setEnabled(False)
        self.timing_spin.setEnabled(False)
        QApplication.processEvents()

        self._should_reset = True
        # Gracefully shutdown all node servers
        for node in self.nodes_logic:
            try:
                if hasattr(node, 'server') and node.server:
                    node.server.shutdown()
                    node.server.server_close()
                    node.server = None
            except Exception:
                pass
        # Wait a bit to ensure sockets are released
        import time
        time.sleep(0.2)
        self.scene.clear()
        self.nodes_logic.clear()
        self.visual_nodes.clear()
        self.threads.clear()
        self._step_event = threading.Event()
        self._step_mode = not self.run_checkbox.isChecked()
        self._should_reset = False
        self.allow_initial_color_change = True
        self.edge_items.clear()
        self.setup_simulation()

        # Hide waiting overlay and re-enable controls
        self.waiting_overlay.setVisible(False)
        self.step_button.setEnabled(True)
        self.run_checkbox.setEnabled(True)
        self.reset_button.setEnabled(True)
        self.timing_spin.setEnabled(True)



    def setup_simulation(self):
        """Initializes the snowflake network and creates graphic items."""
        count = snowflake.NODE_COUNT
        # A. Create Logic Nodes (from your snowflake.py)
        for i in range(count):
            node = snowflake.Node(i, port=5000+i)
            self.nodes_logic.append(node)

        # B. Create Visual Elements (Circle Layout)
        center_x, center_y = 0, 0
        angle_step = 2 * math.pi / count
        for i, node_logic in enumerate(self.nodes_logic):
            angle = i * angle_step
            x = center_x + SCENE_RADIUS * math.cos(angle)
            y = center_y + SCENE_RADIUS * math.sin(angle)
            v_node = VisualNode(x, y, NODE_RADIUS, node_logic, main_window=self, idx=i)
            self.scene.addItem(v_node)
            self.visual_nodes.append(v_node)

        # Create Edges (Fully connected visualization)
        pen = QPen(QColor(200, 200, 200), 1)
        pen.setStyle(Qt.PenStyle.DashLine)
        for i in range(len(self.visual_nodes)):
            for j in range(i + 1, len(self.visual_nodes)):
                n1 = self.visual_nodes[i]
                n2 = self.visual_nodes[j]
                line = QGraphicsLineItem(n1.x(), n1.y(), n2.x(), n2.y())
                line.setPen(pen)
                line.setZValue(-1)
                self.scene.addItem(line)
                self.edge_items[(i, j)] = line
                self.edge_items[(j, i)] = line

        # C. Start the Simulation Threads
        print("Starting Simulation Threads...")
        for idx, node in enumerate(self.nodes_logic):
            t_listen = threading.Thread(target=node.listener, daemon=True)
            t_listen.start()
            self.threads.append(t_listen)
            t_loop = threading.Thread(target=self.node_loop_stepper, args=(node, idx), daemon=True)
            t_loop.start()
            self.threads.append(t_loop)

    def node_loop_stepper(self, node, idx):
        import random
        loop = 0
        while True:
            with node.decided_lock:
                if node.decided:
                    break
            # Step mode: wait for event
            if self._step_mode:
                self._step_event.wait()
                self._step_event.clear()
            else:
                threading.Event().wait(self.timing_spin.value() / 1000.0)
            if self._should_reset:
                break
            # --- Copy of node.loop() body, but only one iteration per call ---
            if node.crash_prob > 0 and random.random() < node.crash_prob:
                print(f"[Node {node.id}] PANNE SIMULÉE ! Le processus s'arrête brutalement.")
                import os
                os._exit(1)
            loop += 1
            print(f"[Node {node.id}] Itération {loop}, état actuel: {node.state.value}, compteur: {node.counter}")
            # --- Query visualization ---
            peers = [port for port, info in node.neighbors.items() if not info["broken_link"]]
            if len(peers) >= node.sample_size:
                import random as _random
                sampled_ports = _random.sample(peers, k=node.sample_size)
            else:
                sampled_ports = peers
            # Map port to node idx
            port_to_idx = {5000 + i: i for i in range(len(self.nodes_logic))}
            for peer_port in sampled_ports:
                j = port_to_idx.get(peer_port)
                if j is not None:
                    # Emit signal to main thread to draw arrow
                    self.query_arrow_signal.emit(idx, j)
            # --- End query visualization ---
            state_counts = node.query_peers()
            if all(count == 0 for count in state_counts.values()):
                print(f"[Node {node.id}] Aucun voisin ne répond, arrêt du noeud.")
                if node.server:
                    node.server.shutdown()
                break
            maj = False
            for state, count in state_counts.items():
                print(f"[Node {node.id}] État {state}: {count}")
                if count >= node.acceptance_threshold:
                    maj = True
                    if node.state.value == state:
                        with node.counter_lock:
                            node.counter += 1
                    else:
                        with node.state_lock, node.counter_lock:
                            node.state = snowflake.States(state)
                            node.counter = 1
                    if node.counter >= node.consecutive_success_threshold:
                        with node.decided_lock:
                            node.decided = True
                        print(f"[Node {node.id}] Décidé sur l'état {node.state.value}")
                        import time
                        print(f"[Node {node.id}] Grâce : je reste disponible 5s pour les autres...")
                        time.sleep(5)
                        if node.server:
                            node.server.shutdown()
                        return
            if not maj:
                with node.counter_lock:
                    node.counter = 0


    def _draw_query_arrow(self, src_idx, dst_idx):
        # Draw a temporary arrow from src to dst (main thread only)
        # Remove old arrows if too many
        if not hasattr(self, 'arrow_items'):
            self.arrow_items = []
        src_node = self.visual_nodes[src_idx]
        dst_node = self.visual_nodes[dst_idx]
        x1, y1 = src_node.x(), src_node.y()
        x2, y2 = dst_node.x(), dst_node.y()
        dx, dy = x2 - x1, y2 - y1
        dist = math.hypot(dx, dy)
        if dist == 0:
            return
        shrink = NODE_RADIUS * 0.9
        x1a = x1 + dx * shrink / dist
        y1a = y1 + dy * shrink / dist
        x2a = x2 - dx * shrink / dist
        y2a = y2 - dy * shrink / dist
        pen = QPen(self.QUERY_HIGHLIGHT_COLOR, 3)
        line = QGraphicsLineItem(x1a, y1a, x2a, y2a)
        line.setPen(pen)
        line.setZValue(1)
        self.scene.addItem(line)
        angle = math.atan2(y2a - y1a, x2a - x1a)
        arrow_size = 18
        angle1 = angle + math.pi / 8
        angle2 = angle - math.pi / 8
        x3 = x2a - arrow_size * math.cos(angle1)
        y3 = y2a - arrow_size * math.sin(angle1)
        x4 = x2a - arrow_size * math.cos(angle2)
        y4 = y2a - arrow_size * math.sin(angle2)
        arrow1 = QGraphicsLineItem(x2a, y2a, x3, y3)
        arrow2 = QGraphicsLineItem(x2a, y2a, x4, y4)
        for arr in (arrow1, arrow2):
            arr.setPen(pen)
            arr.setZValue(1)
            self.scene.addItem(arr)
        src_node.setPen(QPen(self.QUERY_HIGHLIGHT_COLOR, 5))
        self.arrow_items.append((line, arrow1, arrow2, src_node))
        def cleanup():
            for item in (line, arrow1, arrow2):
                self.scene.removeItem(item)
            with src_node.node_logic.decided_lock:
                if not src_node.node_logic.decided:
                    src_node.setPen(QPen(Qt.GlobalColor.black, 2))
        QTimer.singleShot(self.QUERY_HIGHLIGHT_MS, cleanup)



    def update_ui(self):
        """Called periodically by QTimer to refresh node visuals."""
        for v_node in self.visual_nodes:
            v_node.update_label_text()



    def closeEvent(self, event):
        self._should_reset = True
        super().closeEvent(event)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())