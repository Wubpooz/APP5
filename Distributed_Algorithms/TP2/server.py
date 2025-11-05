import socket, json

HOST = '127.0.0.1' 
PORT = 8000

"""
socket(family=a, type=t)
AF_INET: la famille d'adresses de la prise. AF_INET correspond à IPv4
SOCK_STREAM: le type de la prise. Plusieurs valeurs sont possible, mais on 
             utilisera SOCK_STREAM (TCP). 
Voir la doc pour d'autres arguments
"""

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    """
    bind(address)
    address dépend de la famille d'addresses lors de la création de la prise. 
    Pour IPv4, c'est un couple (ip,port)
    """
    s.bind((HOST, PORT))
    s.listen()
    print("Serveur: en écoute...")
    
    conn, addr = s.accept() # Blocant
    
    with conn:
        print(f"Connecté par {addr}")
        data = conn.recv(1024) # Recevoir des octets
        
        # Le pattern de décodage
        msg_str = data.decode('utf-8')
        msg_obj = json.loads(msg_str)
        
        print(f"Reçu: {msg_obj}")



