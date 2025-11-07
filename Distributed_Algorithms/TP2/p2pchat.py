import threading
import json
import sys
import socket
import queue
import time
import readline

# Features: colors, timestamps, usernames, multiport, exit, locked printing


# ANSI color codes
RESET = "\033[0m"
YELLOW = "\033[33m"
LIGHT_BLUE = "\033[94m"
RED = "\033[31m"
ORANGE = "\033[33m"
PURPLE = "\033[35m"

# On veut que les messages reçus n'interrompent pas la saisie de l'utilisateur donc on utilise un lock et on flush en gardant son input, keep same socket
_print_lock: threading.Lock = threading.Lock()
_current_prompt: str = ""

def safe_print(*args, **kwargs) -> None:
  with _print_lock:
    # Save current input buffer before clearing
    current_input: str = readline.get_line_buffer()

    # Clear current line and move cursor to beginning to overwrite the prompt and input to make the prompt always last on the terminal
    sys.stdout.write('\r' + ' ' * (len(_current_prompt) + len(current_input) + 10) + '\r')
    sys.stdout.flush()

    print(*args, **kwargs)

    # Reprint the prompt with the saved input
    if _current_prompt:
      sys.stdout.write(_current_prompt + current_input)
      sys.stdout.flush()

def safe_input(prompt: str) -> str:
  global _current_prompt
  # On s'assure que le prompt is safely set
  with _print_lock:
    _current_prompt = prompt

  try:
    result = input(prompt)
    return result
  finally:
    with _print_lock:
      _current_prompt = ""


def server(host: str, port: int, buffsize: int, exit_event: threading.Event) -> None:
  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))
    s.listen()
    s.settimeout(1.0)  # Add timeout so accept() doesn't block forever
    
    try:
      def handle_conn(conn: socket.socket):
        try:
          with conn:
            conn.settimeout(1.0)  # timeout for recv()
            buffer = b""  # accumulate bytes to support multiple messages per recv
            while not exit_event.is_set():
              try:
                data = conn.recv(buffsize)
                if not data:
                  # connection closed by peer
                  break

                buffer += data
                # Process all full lines (NDJSON framing)
                while b"\n" in buffer:
                  line, buffer = buffer.split(b"\n", 1)
                  if not line:
                    continue
                  try:
                    msg_str = line.decode('utf-8')
                    msg_obj = json.loads(msg_str)
                    pretty_msg = f"{LIGHT_BLUE}[{msg_obj['timestamp']}] {msg_obj['sender']}: {msg_obj['message']}{RESET}"
                    safe_print(pretty_msg)
                  except json.JSONDecodeError as e:
                    # Skip malformed line but keep the connection open
                    safe_print(f"{ORANGE}[DEBUG] JSON invalide: {e}{RESET}")
                    continue
              except socket.timeout:
                # No data this tick; loop back to check exit_event
                continue
        except Exception as e:
          safe_print(f"{ORANGE}[DEBUG] Erreur lors du traitement: {e}{RESET}")

      while not exit_event.is_set():
        try:
          conn, addr = s.accept()
          # Handle each connection in its own thread so multiple peers can stay connected
          threading.Thread(target=handle_conn, args=(conn,), daemon=True).start()
        except socket.timeout:
          # Check exit_event again
          continue
        except Exception as e:
          if not exit_event.is_set():
            safe_print(f"{RED}Erreur accept: {e}{RESET}")
          break
    except Exception as e:
      if not exit_event.is_set():
        safe_print(f"{RED}Erreur serveur: {e}{RESET}")


def sender(host: str, port_in: int, port_out: list[int], message_queue: queue.Queue, exit_event: threading.Event, username: str|None) -> None:
  socks: dict[int, socket.socket|None] = {p: None for p in port_out}

  def ensure_connection(port: int) -> bool:
    # Already connected
    if socks.get(port) is not None:
      return True
    # Try to (re)connect
    try:
      s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
      s.connect((host, port))
      socks[port] = s
      return True
    except Exception as e:
      safe_print(f"{ORANGE}Impossible de se connecter au peer sur le port {port}: {e}{RESET}")
      # ensure we keep None so we retry later
      socks[port] = None
      return False
  

  while not exit_event.is_set():
    try:
      # Use timeout so we can check exit_event periodically
      message_txt: str = message_queue.get(timeout=0.5)
    except queue.Empty:
      continue

    try:
      if message_txt == None or isinstance(message_txt, str) and message_txt.lower() == 'exit':
        break
      
      timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
      message = {
        "sender": username or f"Peer:{port_in}",
        "timestamp": timestamp,
        "message": message_txt,
      }
      # newline-delimited JSON framing so the server can parse multiple messages per recv
      msg_str: str = json.dumps(message) + "\n"
      msg_bytes: bytes = msg_str.encode('utf-8')

      sent_count: int = 0
      for port in port_out:
        if not ensure_connection(port):
          # connection attempt already logged in ensure_connection
          continue
        try:
          s = socks.get(port)
          if s is not None:
            s.sendall(msg_bytes)
            sent_count += 1
        except ConnectionRefusedError:
          safe_print(f"{ORANGE}Connexion refusée par le peer sur le port {port}{RESET}")
          continue
        except Exception as e:
          safe_print(f"{RED}Erreur lors de l'envoi au peer sur le port {port}: {e}{RESET}")
          try:
            s = socks.get(port)
            if s is not None:
              try:
                s.shutdown(socket.SHUT_RDWR)
              except Exception:
                pass
              s.close()
          except Exception as e:
            safe_print(f"{RED}Erreur lors de la fermeture du socket: {e}{RESET}")
          socks[port] = None
          continue
 
      if sent_count > 0:
        safe_print(f"{PURPLE}Message envoyé à {sent_count} peer{'s' if sent_count > 1 else ''}{RESET}")
      else:
        safe_print(f"{RED}Échec. Tous les serveurs sont offline?{RESET}")

    except Exception as e:
      safe_print(f"{ORANGE}[DEBUG] Erreur client: {e}{RESET}")
    finally:
      # mark task done for this message; keep sockets open for persistence
      message_queue.task_done()

  for s in filter(None, list(socks.values())):
    try:
      s.close()
    except Exception as e:
      safe_print(f"{RED}Erreur lors de la fermeture du socket: {e}{RESET}")
      continue


def main():
  if len(sys.argv) < 3:
    safe_print(f"{RED}Usage: python p2pchat.py <port_in> <port_out> [<port_out> ...] [-u <username>]{RESET}")
    return

  # Parse arguments
  username = None
  args = sys.argv[1:]
  
  # Check for username flag
  if '-u' in args:
    u_index = args.index('-u')
    if u_index + 1 < len(args):
      username = args[u_index + 1]
      # Remove -u and username from args
      args = args[:u_index] + args[u_index+2:]
  
  if len(args) < 2:
    safe_print(f"{RED}Usage: python p2pchat.py <port_in> <port_out> [<port_out> ...] [-u <username>]{RESET}")
    return

  port_in = int(args[0])
  port_out = [int(args[i]) for i in range(1, len(args))]
  host = '127.0.0.1'
  buffsize = 1024

  message_queue = queue.Queue()
  exit_event = threading.Event()
  server_thread = threading.Thread(target=server, args=(host, port_in, buffsize, exit_event))
  sender_thread = threading.Thread(target=sender, args=(host, port_in, port_out, message_queue, exit_event, username))

  username_display = f" as {username}" if username else ""
  safe_print(f"Starting P2P chat on port {port_in}{username_display} connecting to peer port{'s' if len(port_out) > 1 else ''} {port_out}")
  sender_thread.start()
  server_thread.start()
  
  try:
    while True:
      message_text = safe_input("> ")
      if message_text.lower() == 'exit':
        exit_event.set()
        break
      message_queue.put(message_text)
  except KeyboardInterrupt:
    safe_print(f"\n{PURPLE}Interrupted by user{RESET}")
    message_queue.put('exit')
    exit_event.set()

  message_queue.join()
  sender_thread.join(timeout=2.0)
  server_thread.join(timeout=2.0)
  
  safe_print(f"{PURPLE}Chat terminated.{RESET}")


if __name__ == "__main__":
  main()