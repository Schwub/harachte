import sys
import os
import threading
import serial
import time
sys.path.append('../model')
os.chdir('../model')
from model import MODEL
import cyueye.cyueye

def connect_camera(cam_format=9):
    cam = cyueye.Cam(cam_format)
    MODEL['camera']['camera'] = cam
    MODEL['camera']['height'] = cam.height
    MODEL['camera']['width'] = cam.width

def connect_board(serial_name='/dev/ttyUSB0', baud_rate='115200'):
    board = MODEL['board']
    board['connect_board'] = False
    try:
        serial_port = serial.Serial(serial_name, baud_rate)
        serial_port.flushInput()
        serial_port.flushOutput()
        serial_port.write('\x18\r\n')
        serial_port.readline()
        version = serial_port.readline()
        if "Grbl 1.1g ['$' for help]" not in version:
            raise Exception("Wrong Firmware")
    except Exception as exception:
        raise exception
    board['board'] = serial_port
    board['serial_name'] = serial_name
    board['baud_rate'] = baud_rate
    board['connected'] = True

def send_g_code_to_board(gcode):
    board = MODEL['board']
    if board['connected'] is not True:
        raise Exception('Board is not connected')
    board['board'].flushInput()
    board['board'].flushOutput()
    board['board'].write(gcode + "\r\n")


if __name__ == '__main__':
    connect_board()
    send_g_code_to_board("$120=200")
    send_g_code_to_board("G1F200")
    send_g_code_to_board("G1X5")

