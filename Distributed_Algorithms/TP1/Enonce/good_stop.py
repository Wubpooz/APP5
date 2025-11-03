import threading
import time

def worker_good(stop_flag):
    while not stop_flag[0]:  # Vérifier le signal
        print("Working...")
        time.sleep(1)
    print("Stopping...")

stop_flag = [False]  # Liste partagée
t = threading.Thread(target=worker_good, args=(stop_flag,))
t.start()

time.sleep(3)
stop_flag[0] = True  # Signal d'arrêt
t.join()


