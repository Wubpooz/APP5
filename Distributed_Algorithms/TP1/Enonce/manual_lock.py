# DEMO 2
import threading
import queue
import time
import random
import os


counter_locked_manual = 0
counter_lock_manual = threading.Lock()

def increment_with_manual_lock():
    global counter_locked_manual
    for _ in range(1000000):
        
        # 1. Manually acquire the lock
        counter_lock_manual.acquire()
        
        try:
            # This is the "critical section"
            if (random.random() > 0.5):
                time.sleep(0)
            counter_locked_manual += 1
        finally:
            # 2. Manually release the lock
            # The 'finally' guarantees it releases even if the 'try' block has an error
            counter_lock_manual.release()

t3 = threading.Thread(target=increment_with_manual_lock)
t4 = threading.Thread(target=increment_with_manual_lock)

t3.start()
t4.start()

t3.join()
t4.join()

# Expected: 2,000,000
# Actual: 2,000,000
print(f"Final counter (manual lock): {counter_locked_manual}")