import threading
import json
import sys
import socket
import queue
import time

# ANSI color codes
RESET = "\033[0m"
YELLOW = "\033[33m"
LIGHT_BLUE = "\033[94m"
RED = "\033[31m"

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

def server(host, port, buffsize):
  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))
    s.listen()
    # safe_print("Serveur: en écoute...")
    try:
      while True:
        conn, addr = s.accept()
        with conn:
          try:
            # safe_print(f"Connecté par {addr}")
            data = conn.recv(buffsize)
            if not data:
              continue

            msg_str = data.decode('utf-8')
            msg_obj = json.loads(msg_str)

            pretty_msg = f"{YELLOW}[{msg_obj['timestamp']}] {msg_obj['sender']}: {msg_obj['message']}{RESET}"
            safe_print(pretty_msg)
          except Exception as e:
            safe_print(f"Erreur lors du traitement: {e}")
            continue
    except Exception as e:
      safe_print(f"Erreur serveur: {e}")


def sender(host, port_in, port_out, message_queue):
  while True:
    message_txt = message_queue.get()
    try:
      if message_txt is None or message_txt.lower() == 'exit':
        safe_print(f"{LIGHT_BLUE}Exiting chat.{RESET}")
        break

      timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
      message = {
        "sender": f"Peer:{port_in}",
        "timestamp": timestamp,
        "message": message_txt,
      }
      msg_str = json.dumps(message)
      msg_bytes = msg_str.encode('utf-8')

      for port in port_out:
        try:
          with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((host, port))
            s.sendall(msg_bytes)
            safe_print(f"{LIGHT_BLUE}Message envoyé{RESET}")
        except ConnectionRefusedError:
          safe_print(f"{RED}Échec. Serveur offline?{RESET}")
          continue
        except Exception:
          safe_print(f"{RED}Échec. Unknown error.{RESET}")
          continue

    except Exception as e:
      safe_print(f"Erreur client: {e}")
    finally:
      message_queue.task_done()




def main():
  if len(sys.argv) < 3:
    safe_print("Usage: python p2pchat.py <port_in> [<port_out> ...]")
    return

  port_in = int(sys.argv[1])
  port_out = [int(sys.argv[i]) for i in range(2, len(sys.argv))]
  host = '127.0.0.1' #sys.argv[3] if len(sys.argv) > 3 else '127.0.0.1'
  buffsize = 1024 #sys.argv[4] if len(sys.argv) > 4 else 1024

  message_queue = queue.Queue()
  server_thread = threading.Thread(target=server, args=(host, port_in, buffsize))
  sender_thread = threading.Thread(target=sender, args=(host, port_in, port_out, message_queue))

  safe_print(f"Starting P2P chat on port {port_in} connecting to peer on port{'s' if len(port_out) > 1 else ''} {port_out}")
  sender_thread.start()
  server_thread.start()
  

  while True:
    message_text = safe_input("> ") #Enter message (or 'exit' to quit):
    message_queue.put(message_text)
    if message_text.lower() == 'exit':
      server_thread.join()
      break

  message_queue.join()
  sender_thread.join()


if __name__ == "__main__":
  main()