import json
import queue
from random import choice, sample
from enum import Enum
import socket
import socketserver
import threading
import argparse

NODE_COUNT = 6

# ANSI color codes
RESET = "\033[0m"
YELLOW = "\033[33m"
LIGHT_BLUE = "\033[94m"
RED = "\033[31m"
ORANGE = "\033[33m"
PURPLE = "\033[35m"

class States(Enum):
  BLUE = "BLUE"
  RED = "RED"

class Node:
  def __init__(self, id, port=None, initial_state=None, neighbor_ports=None):
    # Configuration
    self.id = id
    self.host = "127.0.0.1"
    self.port = port if port is not None else 5000 + id
    self.neighbors_ports: list[int] = neighbor_ports if neighbor_ports is not None else []
    
    # State
    if initial_state:
      self.state = States[initial_state]
    else:
      self.state = choice(list(States))
    self.counter = 1
    self.decided = False
    
    # Algorithm parameters
    self.sample_size = 3
    self.acceptance_threshold = 2 # > sample_size / 2
    self.consecutive_success_threshold = 10
    
    # Locks
    self.state_lock = threading.Lock()
    self.counter_lock = threading.Lock()
    self.decided_lock = threading.Lock()
    
    # Server
    self.server = None
    
    # Initialize neighbors' ports (défaut: tous les autres nœuds)
    if not self.neighbors_ports:
      for i in range(NODE_COUNT):
        if i != self.id:
          self.neighbors_ports.append(5000 + i)

  def loop(self) -> None:
    """Boucle principale de l'algorithme Snowflake."""
    loop = 0
    while True:
      with self.decided_lock:
        if self.decided:
          break
      
      loop += 1
      print(f"{YELLOW}[Node {self.id}] Itération {loop}, état actuel: {self.state.value}, compteur: {self.counter}{RESET}")
      state_counts = self.query_peers()
      # If all counts are zero, all neighbors are gone
      if all(count == 0 for count in state_counts.values()):
        print(f"{RED}[Node {self.id}] Aucun voisin ne répond, arrêt du noeud.{RESET}")
        if self.server:
          self.server.shutdown()
        break
      
      maj = False
      for state, count in state_counts.items():
        print(f"[Node {self.id}] État {state}: {count}")
        if count >= self.acceptance_threshold:
          maj = True
          if self.state.value == state:
            with self.counter_lock:
              self.counter += 1
          else:
            with self.state_lock, self.counter_lock:
              self.state = States(state)
              self.counter = 1
          if self.counter >= self.consecutive_success_threshold:
            with self.decided_lock:
              self.decided = True
            print(f"{PURPLE}[Node {self.id}] Décidé sur l'état {self.state.value}{RESET}")
            # Grâce : rester disponible pour que les autres noeuds puissent décider
            import time
            print(f"{LIGHT_BLUE}[Node {self.id}] Grâce : je reste disponible 5s pour les autres...{RESET}")
            time.sleep(5)
            if self.server:
              self.server.shutdown()
            return
      if not maj:
        with self.counter_lock:
          self.counter = 0 

      threading.Event().wait(1)  # Pause avant la prochaine itération
      


  def listener(self) -> None:
    """Thread qui écoute les connexions entrantes et répond aux requêtes QUERY"""
    node = self
    
    class QueryHandler(socketserver.StreamRequestHandler):
      def handle(self):
        for line in self.rfile:
          if line.strip() == b'QUERY':
            with node.state_lock:
              response = json.dumps({"state": node.state.value, "counter": node.counter})
            self.wfile.write((response + "\n").encode())
    
    self.server = socketserver.ThreadingTCPServer((self.host, self.port), QueryHandler)
    self.server.allow_reuse_address = True
    print(f"[Node {self.id}] Écoute sur {self.host}:{self.port}")
    self.server.serve_forever()
    print(f"[Node {self.id}] Serveur arrêté")

  def query_peers(self) -> dict[str, int]:
    """Interroge un échantillon aléatoire de pairs et retourne le compte des états reçus."""
    peers: list[int] = sample(self.neighbors_ports, k=self.sample_size)
    responses: list[dict] = []

    for peer_port in peers:
      try:
        with socket.create_connection((self.host, peer_port), timeout=2) as s:
          s.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
          s.sendall(b"QUERY\n")
          s.settimeout(2.0)
          buffer: bytes = b""
          while True:
            data: bytes = s.recv(4096)
            if not data:
              break
            buffer += data
            if b"\n" in buffer:
              line, _ = buffer.split(b"\n", 1)
              msg_str: str = line.decode('utf-8')
              msg_obj: dict = json.loads(msg_str)
              responses.append(msg_obj)
              break
      except Exception as e:
        print(f"{ORANGE}[DEBUG] Erreur de connexion au pair {peer_port}: {e}{RESET}")

    state_counts: dict[str, int] = {state.value: 0 for state in States}
    for response in responses:
      state_counts[response["state"]] += 1
    return state_counts



class Network:
  def __init__(self, node_count: int):
    self.nodes: list[Node] = [Node(i) for i in range(node_count)]
    self.threads: list[threading.Thread] = []

  def start(self) -> None:
    """Démarre tous les nœuds et leurs threads d'écoute."""
    for node in self.nodes:
      listener_thread = threading.Thread(target=node.listener, daemon=True)
      listener_thread.start()
      self.threads.append(listener_thread)

    for node in self.nodes:
      loop_thread = threading.Thread(target=node.loop, daemon=True)
      loop_thread.start()
      self.threads.append(loop_thread)

    for thread in self.threads:
      thread.join()


"""Usage example:
- Pour lancer un seul noeud avec configuration personnalisée:
python snowflake.py <node_id> --port <port> --color <BLUE|RED> --neighbors <port1> <port2> <port3> ...

- Pour lancer un seul noeud avec valeurs par défaut:
python snowflake.py <node_id>

- Pour lancer tous les noeuds ensemble (dans le même processus/terminal):
python snowflake.py
"""


if __name__ == "__main__":
  import sys
  
  if len(sys.argv) > 1:
    # Mode: lancer un seul noeud (pour simulation manuelle)
    parser = argparse.ArgumentParser(description='Lancer un noeud Snowflake')
    parser.add_argument('node_id', type=int, help='ID du noeud')
    parser.add_argument('--port', type=int, help='Port du noeud (défaut: 5000 + node_id)')
    parser.add_argument('--color', type=str, choices=['BLUE', 'RED'], help='Couleur initiale (défaut: aléatoire)')
    parser.add_argument('--neighbors', type=int, nargs='+', help='Liste des ports des voisins (défaut: tous les autres noeuds)')
    
    args = parser.parse_args()
    
    node = Node(
      id=args.node_id,
      port=args.port,
      initial_state=args.color,
      neighbor_ports=args.neighbors
    )
    
    # Afficher l'état initial
    print(f"{YELLOW}[Node {node.id}] Port: {node.port}, État initial: {node.state.value}{RESET}")
    print(f"{YELLOW}[Node {node.id}] Voisins: {node.neighbors_ports}{RESET}")
    
    # Lancer le listener dans un thread
    listener_thread = threading.Thread(target=node.listener, daemon=True)
    listener_thread.start()
    
    # Attendre un peu que tous les noeuds démarrent
    threading.Event().wait(2)
    
    # Lancer la boucle principale
    node.loop()
    
    # Afficher l'état final et terminer
    print(f"{YELLOW}[Node {node.id}] État final: {node.state.value}{RESET}")
  else:
    # Mode: lancer tous les noeuds ensemble (pour tests automatiques)
    print(f"{YELLOW}Démarrage du réseau avec {NODE_COUNT} noeuds...{RESET}")
    network = Network(NODE_COUNT)
    network.start()
