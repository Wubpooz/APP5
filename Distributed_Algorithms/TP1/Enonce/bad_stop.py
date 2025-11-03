import threading
import time

def worker_bad():
    while True:  
        print("Working...")
        time.sleep(1)

t = threading.Thread(target=worker_bad)
t.start()




