import threading
import json
import sys
import socket
import queue
import time

_print_lock = threading.Lock()

def safe_print(*args, **kwargs):
  with _print_lock:
    print(*args, **kwargs)

def safe_print_input(prompt):
  with _print_lock:
    return input(prompt)
#TODO make it free the lock when the server receives an input and reprint afterwards

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

            safe_print(f"Reçu: {msg_obj}")
          except Exception as e:
            safe_print(f"Erreur lors du traitement: {e}")
            continue
    except Exception as e:
      safe_print(f"Erreur serveur: {e}")


def sender(host, port_in, port_out, message_queue):
  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    while True:
      message_txt = message_queue.get()
      if message_txt.lower() == 'exit':
        safe_print("Exiting chat.")
        message_queue.task_done()
        break

      try:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        message = {
          "sender": f"Peer:{port_in}",
          "timestamp": timestamp,
          "message": message_txt,
        }
        msg_str = json.dumps(message)
        msg_bytes = msg_str.encode('utf-8')

        for port in port_out:
          s.connect((host, port))
          s.sendall(msg_bytes)

        safe_print("Client: Message envoyé\n")
      except ConnectionRefusedError:
        safe_print("Client: Échec. Serveur offline?")
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
  server_thread = threading.Thread(target=server, args=(host, port_in, buffsize), daemon=True)
  sender_thread = threading.Thread(target=sender, args=(host, port_in, port_out, message_queue), daemon=True)

  safe_print(f"Starting P2P chat on port {port_in} connecting to peer on port{'s' if len(port_out) > 1 else ''} {port_out}")
  sender_thread.start()
  server_thread.start()
  

  while True:
    message_text = input("Enter message (or 'exit' to quit):\n")
    message_queue.put(message_text)
    if message_text.lower() == 'exit':
      break
  message_queue.join()
  server_thread.join()
  sender_thread.join()



if __name__ == "__main__":
  main()