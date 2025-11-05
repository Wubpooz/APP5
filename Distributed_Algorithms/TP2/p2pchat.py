import threading
import json
import sys
import socket
import queue
import time

# Features: colors, timestamps, usernames, multiport, exit, locked printing


# ANSI color codes
RESET = "\033[0m"
YELLOW = "\033[33m"
LIGHT_BLUE = "\033[94m"
RED = "\033[31m"

# On veut que les messages reçus n'interrompent pas la saisie de l'utilisateur donc on utilise un lock et on flush
_print_lock = threading.Lock()
_current_prompt = ""

def safe_print(*args, **kwargs):
  with _print_lock:
    # Clear current line and move cursor to beginning
    sys.stdout.write('\r' + ' ' * (len(_current_prompt) + 80) + '\r')
    sys.stdout.flush()
    
    # Print the message
    print(*args, **kwargs)
    
    # Reprint the prompt
    if _current_prompt:
      sys.stdout.write(_current_prompt)
      sys.stdout.flush()

# TODO keep inputed text in input when reprinting prompt
def safe_input(prompt):
  global _current_prompt
  with _print_lock:
    _current_prompt = prompt
    sys.stdout.write(prompt)
    sys.stdout.flush()
  
  try:
    result = sys.stdin.readline().rstrip('\n')
    return result
  finally:
    with _print_lock:
      _current_prompt = ""


def server(host, port, buffsize, exit_event):
  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))
    s.listen()
    s.settimeout(1.0)  # Add timeout so accept() doesn't block forever
    
    try:
      while not exit_event.is_set():
        try:
          conn, addr = s.accept()
          with conn:
            try:
              data = conn.recv(buffsize)
              if not data:
                continue

              msg_str = data.decode('utf-8')
              msg_obj = json.loads(msg_str)

              pretty_msg = f"{YELLOW}[{msg_obj['timestamp']}] {msg_obj['sender']}: {msg_obj['message']}{RESET}"
              safe_print(pretty_msg)
            except Exception as e:
              safe_print(f"{RED}Erreur lors du traitement: {e}{RESET}")
              continue
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

# TODO Au lieu de créer un nouveau socket pour chaque message, gardez une connexion ouverte vers le peer
def sender(host, port_in, port_out, message_queue, exit_event, username):
  while not exit_event.is_set():
    try:
      # Use timeout so we can check exit_event periodically
      message_txt = message_queue.get(timeout=0.5)
    except queue.Empty:
      continue

    try:
      timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
      message = {
        "sender": username or f"Peer:{port_in}",
        "timestamp": timestamp,
        "message": message_txt,
      }
      msg_str = json.dumps(message)
      msg_bytes = msg_str.encode('utf-8')

      sent_count = 0
      for port in port_out:
        try:
          with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((host, port))
            s.sendall(msg_bytes)
            sent_count += 1
        except ConnectionRefusedError:
          continue
        except Exception:
          continue
      
      if sent_count > 0:
        safe_print(f"{LIGHT_BLUE}Message envoyé à {sent_count} peer{'s' if sent_count > 1 else ''}{RESET}")
      else:
        safe_print(f"{RED}Échec. Tous les serveurs sont offline?{RESET}")

    except Exception as e:
      safe_print(f"{RED}Erreur client: {e}{RESET}")
    finally:
      message_queue.task_done()


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
    safe_print(f"\n{LIGHT_BLUE}Interrupted by user{RESET}")
    message_queue.put('exit')
    exit_event.set()

  message_queue.join()
  sender_thread.join(timeout=2.0)
  server_thread.join(timeout=2.0)
  
  safe_print(f"{LIGHT_BLUE}Chat terminated.{RESET}")


if __name__ == "__main__":
  main()