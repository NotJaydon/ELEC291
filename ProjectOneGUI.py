import serial.tools.list_ports
import serial
from tkinter import *
import time
from PIL import Image

serial_line = serial.Serial(port=None)

status = True


def guessing_game():
    time.sleep(0.2)
    b2.destroy()
    b1.destroy()
    l1.destroy()
    b3.place(relx=0.3, rely=0.5, anchor=CENTER)
    b4.place(relx=0.7, rely=0.5, anchor=CENTER)
    l3.place(relx=0.5, rely=0.25, anchor=CENTER)
    serial_line.write(b'1')


def guessing_game_choose_right():
    serial_line.write(b'1')


def guessing_game_choose_left():
    serial_line.write(b'0')


def sound_off():
    serial_line.write(b'0')

# List ports
print("Available Ports:")
for port in serial.tools.list_ports.comports():
    print(port)
print()

# Select port
com_select = input("Select COM port: ")
for port in serial.tools.list_ports.comports():
    if com_select in port:
        com_select = str(port)      # Convert to string object -> needed for the serial class constructor
        serial_line = serial.Serial(com_select[0:4], 115200)     # Assuming that all available ports will be labelled COM#
        serial_line.timeout = 5     # Time given to the read line function to read the serial data before termination
        if serial_line.isOpen():    # Confirm that the serial line is open for reading
            print("Connected to " + com_select)
        else:
            serial_line.open()
            print("Connected to " + com_select)
        break
else:
    print("Unavailable Port")       # If specified port is not found in the existing list
    status = False

if status is True:
    master = Tk()
    master.title("ELEC 291 Project One")
    master.geometry("400x350")

    l1 = Label(master,
               text="ELEC 291 GAME NIGHT!",
               fg='#4D4A3A',
               bg='#FEFEFE')

    l1.config(font=("Comic Sans MS bold", 17))

    l1.place(relx=0.5, rely=0.1, anchor=CENTER)

    bg = PhotoImage(file="E:\\Circuit_1.png")

    l2 = Label(master, image=bg)

    l2.place(x=0, y=0)

    l2.lower()

    b1 = Button(master,
                text="GUESSING GAME",
                font=("Comic Sans MS", 9),
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=guessing_game,
                height=4,
                width=20,
                bg='#D83C16')

    b1.place(relx=0.5, rely=0.4, anchor=CENTER)

    b2 = Button(master,
                text="SOUND OFF",
                font=("Comic Sans MS", 9),
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=sound_off,
                height=4,
                width=20,
                bg='#D83C16')

    b2.place(relx=0.5, rely=0.7, anchor=CENTER)

    b3 = Button(master,
                text="LEFT",
                font=("Comic Sans MS", 9),
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=guessing_game_choose_left,
                height=4,
                width=20,
                bg='#D83C16')

    b4 = Button(master,
                text="RIGHT",
                font=("Comic Sans MS", 9),
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=guessing_game_choose_right,
                height=4,
                width=20,
                bg='#D83C16')

    l3 = Label(master,
               text="MAKE YOUR GUESS!",
               fg='#4D4A3A',
               bg='#FEFEFE')

    l3.config(font=("Comic Sans MS bold", 17))

    mainloop()

else:
    time.sleep(1)
    print("Program terminated")
