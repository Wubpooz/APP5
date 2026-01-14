import sys
import math
import threading
from PyQt6.QtWidgets import (QApplication, QMainWindow, QGraphicsScene, 
                             QGraphicsView, QGraphicsEllipseItem, QGraphicsLineItem, 
                             QGraphicsTextItem, QVBoxLayout, QWidget, QGraphicsItem)
from PyQt6.QtCore import QTimer, Qt, QPointF, QRectF
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
    def __init__(self, x, y, radius, node_logic):
        super().__init__(-radius, -radius, radius * 2, radius * 2)
        self.node_logic = node_logic  # Reference to the actual snowflake.Node object
        self.setPos(x, y)
        
        # Visual styling
        self.setPen(QPen(Qt.GlobalColor.black, 2))
        self.setBrush(QBrush(COLOR_DEFAULT))
        
        # Flags for interaction (for your "Later" requirements)
        self.setFlag(QGraphicsItem.GraphicsItemFlag.ItemIsMovable)
        self.setFlag(QGraphicsItem.GraphicsItemFlag.ItemIsSelectable)

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
            # Optional: Make it green or glowing if decided, 
            # or keep color but add thick border. Let's keep color but add border.
            self.setPen(QPen(QColor("gold"), 5))
        
        if state_txt == "BLUE":
            self.setBrush(QBrush(COLOR_BLUE))
        elif state_txt == "RED":
            self.setBrush(QBrush(COLOR_RED))
        else:
            self.setBrush(QBrush(COLOR_DEFAULT))


from PyQt6.QtWidgets import QPushButton, QHBoxLayout, QLabel, QSpinBox, QCheckBox

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
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

        # 2. Initialize the Simulation Data
        self.nodes_logic = []      # List of snowflake.Node objects
        self.visual_nodes = []     # List of VisualNode items
        self.threads = []          # Keep track of threads
        self._step_event = threading.Event()
        self._step_mode = True
        self._should_reset = False

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
        self._step_event.set()

    def toggle_run_mode(self, state):
        self._step_mode = not self.run_checkbox.isChecked()
        if not self._step_mode:
            self._step_event.set()  # Unblock if waiting

    def update_timer_interval(self, value):
        self.timer.setInterval(value)

    def reset_simulation(self):
        self._should_reset = True
        # Stop all threads and clear scene
        self.scene.clear()
        self.nodes_logic.clear()
        self.visual_nodes.clear()
        self.threads.clear()
        self._step_event = threading.Event()
        self._step_mode = not self.run_checkbox.isChecked()
        self._should_reset = False
        self.setup_simulation()



    def setup_simulation(self):
        """Initializes the snowflake network and creates graphic items."""
        count = snowflake.NODE_COUNT
        
        # A. Create Logic Nodes (from your snowflake.py)
        for i in range(count):
            # We pass specific ports to ensure they don't clash
            node = snowflake.Node(i, port=5000+i)
            self.nodes_logic.append(node)

        # B. Create Visual Elements (Circle Layout)
        center_x, center_y = 0, 0
        angle_step = 2 * math.pi / count

        # Create Nodes
        for i, node_logic in enumerate(self.nodes_logic):
            angle = i * angle_step
            x = center_x + SCENE_RADIUS * math.cos(angle)
            y = center_y + SCENE_RADIUS * math.sin(angle)

            v_node = VisualNode(x, y, NODE_RADIUS, node_logic)
            self.scene.addItem(v_node)
            self.visual_nodes.append(v_node)

        # Create Edges (Fully connected visualization)
        # Note: We draw lines for every connection. If there are many nodes, 
        # you might want to only draw lines to 'active' neighbors.
        pen = QPen(QColor(200, 200, 200), 1)
        pen.setStyle(Qt.PenStyle.DashLine)
        
        for i in range(len(self.visual_nodes)):
            for j in range(i + 1, len(self.visual_nodes)):
                n1 = self.visual_nodes[i]
                n2 = self.visual_nodes[j]
                line = QGraphicsLineItem(n1.x(), n1.y(), n2.x(), n2.y())
                line.setPen(pen)
                line.setZValue(-1) # Put lines behind nodes
                self.scene.addItem(line)

        # C. Start the Simulation Threads
        # We do NOT use Network.start() because it joins (blocks) the threads.
        # We start them manually here so the GUI keeps running.
        print("Starting Simulation Threads...")
        
        for node in self.nodes_logic:
            # 1. Listener Thread
            t_listen = threading.Thread(target=node.listener, daemon=True)
            t_listen.start()
            self.threads.append(t_listen)
            t_loop = threading.Thread(target=self.node_loop_stepper, args=(node,), daemon=True)
            t_loop.start()
            self.threads.append(t_loop)

    def node_loop_stepper(self, node):
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
                # Auto-run: sleep for timing interval
                threading.Event().wait(self.timing_spin.value() / 1000.0)
            if self._should_reset:
                break
            # --- Copy of node.loop() body, but only one iteration per call ---
            # Simulation de panne aléatoire
            if node.crash_prob > 0 and random.random() < node.crash_prob:
                print(f"[Node {node.id}] PANNE SIMULÉE ! Le processus s'arrête brutalement.")
                import os
                os._exit(1)
            loop += 1
            print(f"[Node {node.id}] Itération {loop}, état actuel: {node.state.value}, compteur: {node.counter}")
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