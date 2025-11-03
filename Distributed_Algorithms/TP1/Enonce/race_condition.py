# DEMO 1
import threading
import queue
import time
import random
import os

counter = 0

def increment_counter():
    global counter
    for _ in range(1000000):
        # This is the "critical section"
        # Read the value
        current_val = counter
        # Modify the value
        new_val = current_val + 1
        
        # if (random.random() > 0.5):
        #     time.sleep(0)
        # Write the value back
        counter = new_val

t1 = threading.Thread(target=increment_counter)
t2 = threading.Thread(target=increment_counter)

t1.start()
t2.start()

t1.join()
t2.join()

# Expected: 2000000
# Actual: ??? (e.g., 1120458)
print(f"Final counter (no lock): {counter}")
