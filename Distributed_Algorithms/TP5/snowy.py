import json
import queue
from random import choice, sample
from enum import Enum
import socket
import socketserver
import threading
import argparse
import abc

NODE_COUNT = 6
MAX_CONN_RETRIES = 3  # Nombre maximum de tentatives de connexion à un pair

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
  
class Algorithms(Enum):
  SNOWFLAKE = "SNOWFLAKE"
  SNOWBALL = "SNOWBALL"

class Node(abc.ABC):
  def __init__(self, id, port=None, initial_state=None, neighbor_ports=None, crash_prob=0.0, host="127.0.0.1"):
    # Configuration
    self.id = id
    self.host = host
    self.port = port if port is not None else 5000 + id
    self.neighbors: dict[int, dict] = {}
    if neighbor_ports is not None:
      for port in neighbor_ports:
        self.neighbors[port] = {"port": port, "broken_link": False}
    else:
      for i in range(NODE_COUNT):
        if i != self.id:
          neighbor_port = 5000 + i
          self.neighbors[neighbor_port] = {"port": neighbor_port, "broken_link": False}
    
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
    
    # Crash simulation probability
    self.crash_prob = crash_prob
    
    # Locks
    self.state_lock = threading.Lock()
    self.counter_lock = threading.Lock()
    self.decided_lock = threading.Lock()
    
    # Server
    self.server = None
    


  @abc.abstractmethod
  def consensus_algorithm(self, state_counts: dict[str, int]) -> None:
    """Updates self.state and self.counter based on the received state counts."""
    pass

  def loop(self) -> None:
    """Boucle principale de l'algorithme Snowflake."""
    import random
    loop = 0
    while True:
      with self.decided_lock:
        if self.decided:
          break
      # Simulation de panne aléatoire
      if self.crash_prob > 0 and random.random() < self.crash_prob:
        print(f"{RED}[Node {self.id}] PANNE SIMULÉE ! Le processus s'arrête brutalement.{RESET}")
        import os
        os._exit(1)
      
      loop += 1
      print(f"{YELLOW}[Node {self.id}] Itération {loop}, état actuel: {self.state.value}, compteur: {self.counter}{RESET}")
      state_counts = self.query_peers()
      # If all counts are zero, all neighbors are gone
      if all(count == 0 for count in state_counts.values()):
        print(f"{RED}[Node {self.id}] Aucun voisin ne répond, arrêt du noeud.{RESET}")
        if self.server:
          self.server.shutdown()
        break
      
      self.consensus_algorithm(state_counts)
        
      
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
    peers: list[int] = sample([port for port, info in self.neighbors.items() if not info["broken_link"]], k=self.sample_size)
    responses: list[dict] = []

    if not peers:
      print(f"{RED}[Node {self.id}] Aucun pair disponible pour l'interrogation.{RESET}")
      return {state.value: 0 for state in States}

    for peer_port in peers:
      retry = 0
      while retry < MAX_CONN_RETRIES:
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
          break  # Succès, sortir de la boucle de retry
        except (ConnectionRefusedError, ConnectionResetError, TimeoutError, OSError) as e:
          retry += 1
          if retry >= MAX_CONN_RETRIES:
            print(f"{RED}[Node {self.id}] Abandon connexion au pair {peer_port} après {MAX_CONN_RETRIES} tentatives: {e}{RESET}")
            self.neighbors[peer_port]["broken_link"] = True
          else:
            print(f"{ORANGE}[Node {self.id}] Tentative {retry}/{MAX_CONN_RETRIES} échouée vers pair {peer_port}: {e}{RESET}")
        except Exception as e:
          print(f"{ORANGE}[DEBUG] Erreur de connexion au pair {peer_port}: {e}{RESET}")
          break

    state_counts: dict[str, int] = {state.value: 0 for state in States}
    for response in responses:
      state_counts[response["state"]] += 1
    return state_counts


class SnowFlakeNode(Node):
  def consensus_algorithm(self, state_counts: dict[str, int]) -> None:
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


class SnowBallNode(Node):
  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)

    self.d_counts: dict[str, int] = {state.value: 0 for state in States}
    self.last_state: States = self.state

    self.d_counts_lock = threading.Lock()
    self.last_state_lock = threading.Lock()


  def consensus_algorithm(self, state_counts: dict[str, int]) -> None:
    maj = False
    for state, count in state_counts.items():
      print(f"[Node {self.id}] État {state}: {count} et d_count: {self.d_counts[state]}")
      if count >= self.acceptance_threshold:
        maj = True
        with self.d_counts_lock:
          self.d_counts[state] += 1
        
        if self.d_counts[state] > self.d_counts[self.state.value]:
          with self.state_lock:
            self.state = States(state)
            
        if state != self.last_state.value:
          self.last_state = States(state)
          with self.counter_lock:
            self.counter = 1
        else:
          with self.counter_lock:
            self.counter += 1

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



class Network:
  def __init__(self, node_count: int, NodeClass=SnowFlakeNode):
    self.nodes: list[Node] = [NodeClass(i) for i in range(node_count)]
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
python snowy.py <node_id> --port <port> --color <BLUE|RED> --crash-prob <prob> --neighbors <port1> <port2> <port3> ... --host <ip> --algorithm <SNOWFLAKE|SNOWBALL>

- Pour lancer un seul noeud avec valeurs par défaut:
python snowy.py <node_id>

- Pour lancer tous les noeuds ensemble (dans le même processus/terminal):
python snowy.py
 
Options supplémentaires:
- --host <ip> : Adresse IP du noeud (défaut: 127.0.0.1)
- --algorithm <SNOWFLAKE|SNOWBALL> : Algorithme de consensus utilisé par le noeud (défaut: SNOWFLAKE)
 
 - Pour lancer un réseau Snowball automatisé:
 launch_snowball_network.bat [N]: Script pour lancer N noeuds Snowball dans des terminaux séparés.
"""
if __name__ == "__main__":
  import sys
  
  if len(sys.argv) > 1:
    # Mode: lancer un seul noeud (pour simulation manuelle)
    parser = argparse.ArgumentParser(description='Lancer un noeud Snowflake')
    parser.add_argument('node_id', type=int, help='ID du noeud')
    parser.add_argument('--algorithm', type=str, choices=['SNOWFLAKE', 'SNOWBALL'], default='SNOWFLAKE', help='Algorithme de consensus (défaut: SNOWFLAKE)')
    parser.add_argument('--port', type=int, help='Port du noeud (défaut: 5000 + node_id)')
    parser.add_argument('--color', type=str, choices=['BLUE', 'RED'], help='Couleur initiale (défaut: aléatoire)')
    parser.add_argument('--neighbors', type=int, nargs='+', help='Liste des ports des voisins (défaut: tous les autres noeuds)')
    parser.add_argument('--crash-prob', type=float, default=0.0, help='Probabilité de panne aléatoire à chaque itération (0.0 = jamais, 0.05 = 5%)')
    parser.add_argument('--host', type=str, default='127.0.0.1', help='Adresse IP du noeud (défaut: 127.0.0.1)')
    
    args = parser.parse_args()
    
    node_class = SnowFlakeNode if args.algorithm == 'SNOWFLAKE' else SnowBallNode
    node = node_class(
      id=args.node_id,
      port=args.port,
      initial_state=args.color,
      neighbor_ports=args.neighbors,
      crash_prob=args.crash_prob
    )
    
    # Afficher l'état initial
    print(f"{YELLOW}[Node {node.id}] Port: {node.port}, État initial: {node.state.value}{RESET}")
    print(f"{YELLOW}[Node {node.id}] Voisins: {list(node.neighbors.keys())}{RESET}")
    
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
