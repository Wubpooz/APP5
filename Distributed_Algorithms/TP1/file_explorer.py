# Mathieu WAHARTE - APP5 IIM, Algorithmes Distribués

# Use with python file_explorer.py -n 4 -p ./crawlerDir for instance

import os
import threading
import queue
import argparse

RED = "\033[31m"
GREEN = "\033[32m"
RESET = "\033[0m"

def directory_walker(path: str, fileQueue: queue.Queue, num_workers: int):
  if not os.path.exists(path):
    raise FileNotFoundError(f"{path} doesn't exist.")

  for root, _, files in os.walk(path, topdown=False):
   for name in files:
      fileQueue.put(os.path.join(root, name))

  for _ in range(num_workers):
    fileQueue.put(None) # stop flag


def file_ingestor(num_worker: int, fileQueue: queue.Queue):
  while True:
    try:
      filepath = fileQueue.get()
      if filepath == None:
        fileQueue.task_done()
        return
      count = 0
      try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
          for line in f:
            count += len(line.split())
        print(f"{GREEN}Worker {num_worker} found {count} words in the file {filepath}.{RESET}")
      except (FileNotFoundError, IsADirectoryError):
        print(f"{RED}Worker {num_worker} encountered and error reading the file {filepath}, it's either not found or a directory.{RESET}")
      finally:
        fileQueue.task_done()
    except(queue.Empty):
      return



def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("-p", "--path", default=os.path.join(os.getcwd(), "crawlerDir"), help="start directory (default: ./crawlerDir)")
  parser.add_argument("-n", "--workers", type=int, default=4, help="number of worker threads (default: 4)")
  args = parser.parse_args()

  start_path = os.path.expanduser(args.path)
  num_workers = max(1, args.workers)

  fileQueue = queue.Queue()
  walker = threading.Thread(target=directory_walker, args=(start_path, fileQueue, num_workers))
  ingestors = [threading.Thread(target=file_ingestor, args=(i, fileQueue)) for i in range (num_workers)]


  print(f"Starts walking on directory {start_path}.")
  for i in ingestors:
    i.start()
  walker.start()

  walker.join()
  fileQueue.join()
  for i in ingestors:
    i.join()


if __name__ == "__main__":
  main()