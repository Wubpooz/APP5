import socket, json, time

HOST = '127.0.0.1' # Le même serveur
PORT = 8000

# L'objet à envoyer
my_message = {
  "sender": "Client",
  "message": "Hello",
  "timestamp": time.time()
}

# Le pattern d'encodage
msg_str = json.dumps(my_message)
msg_bytes = msg_str.encode('utf-8')

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        """
        socket(family=a, type=t)
        AF_INET: la famille d'adresses de la prise. AF_INET correspond à IPv4
        SOCK_STREAM: le type de la prise. Plusieurs valeurs sont possible, mais on 
                     utilisera SOCK_STREAM (TCP). 
        Voir la doc pour d'autres arguments
        """
        s.connect((HOST, PORT))
        s.sendall(msg_bytes)
        print("Client: Message envoyé")
except ConnectionRefusedError:
    print("Client: Échec. Serveur offline?")



