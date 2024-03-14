import socket
import random


txPSDU = [random.choice([0, 1]) for _ in range(8056)]
byte_array = bytearray(txPSDU)
host="127.0.0.1"
port = 4000                  # The same port as used by the server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#Connect to Server
s.connect((host, port))
i=1
#Read Write infinitly
while True:

    s.sendall(byte_array)
    data = s.recv(1007)
    print('Received',i,": ", repr(data))
    i=i+1
s.close()
