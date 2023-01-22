import socket
from threading import Thread
import threading
import time

HOST        = "172.20.10.4"
PORT_DJANGO = 6005
PORT_CLIENT = 5005
lock      = threading.Lock()
conns     = []

def listen_for_connections_from_django(socket):
    while True:
        conn, _ = socket.accept()
        data    = conn.recv(1024)
        print(data)
        send_data_out(data)

def listen_for_connections_from_clients(socket):
    while True:
        conn, _ = socket.accept()
        lock.acquire()
        conns.append(conn)
        print("new connection from client")
        lock.release()

def send_data_out(data):
    for i, conn in enumerate(conns):
        try:
            conn.send(data)
        except BrokenPipeError:
            print("[ERROR] BrokenPipeError")
            del conns[i]
        except ConnectionAbortedError:
            print("[ERROR] ConnectionAbortedError")
            del conns[i]

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.bind((HOST, PORT_CLIENT))
client_socket.listen()
t1 = Thread(target=listen_for_connections_from_clients, args=(client_socket, ))
t1.start()

django_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
django_socket.bind((HOST, PORT_DJANGO))
django_socket.listen()
t2 = Thread(target=listen_for_connections_from_django, args=(django_socket, ))
t2.start()

while True:
    pass