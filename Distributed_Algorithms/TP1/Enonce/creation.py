import threading


def run (n,c):
    for i in range (n) :
        print (c)

t1 = threading.Thread (target = run , args = ( 100, '#') )
t2 = threading.Thread (target = run , args = ( 100, '!') )


t1.start ()
t2.start ()



