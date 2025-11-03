import threading

def worker():
    result = sum(range(1000000))  # Some calculation
    print(f"Worker: The answer is {result}")

t = threading.Thread(target=worker)
t.start()

print("Main: What's the answer?")
print("Main: Exiting now!")
