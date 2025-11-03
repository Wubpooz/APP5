# DEMO 2.5
import threading
import queue
import time
import random
import os


counter_locked = 0
counter_lock = threading.Lock()

def increment_with_lock():
    global counter_locked
    for _ in range(1000000):
        # Acquire the lock, blocking other threads
        with counter_lock:
            # This code is now "atomic" - only one thread at a time
            if (random.random() > 0.5):
                time.sleep(0)
            counter_locked += 1
        # The 'with' statement automatically releases the lock

t3 = threading.Thread(target=increment_with_lock)
t4 = threading.Thread(target=increment_with_lock)

t3.start()
t4.start()

t3.join()
t4.join()

# Expected: 2,000,000
# Actual: 2,000,000
print(f"Final counter (with lock): {counter_locked}")
time.sleep(1) # Pause for clarity in output
