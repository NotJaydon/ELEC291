import serial.tools.list_ports
import serial
from tkinter import *
import time

serial_line = serial.Serial(port=None)

status = True

def rapid_touch():
    serial_line.write('1'.encode('ascii'))


def sound_off():
    serial_line.write('0'.encode('ascii'))


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
        serial_line = serial.Serial(com_select[0:4], 9600)     # Assuming that all available ports will be labelled COM#
        serial_line.timeout = 5     # Time given to the read line function to read the serial data before termination
        if serial_line.isOpen():    # Confirm that the serial line is open for reading
            print("Connected to " + com_select)
        else:
            serial_line.open()
            print("Connected to " + com_select)
        break
else:
    print("Unavailable Port")       # If specified port is not found in the existing list
    status = True

if status is True:
    master = Tk()
    master.geometry("400x350")

    l1 = Label(master,
               text="291 GAME NIGHT",
               fg='#4D4A4A',
               bg='#FEFEFE')

    l1.config(font=("Comic Sans MS bold", 17))

    l1.place(relx=0.5, rely=0.1, anchor=CENTER)

    bg = PhotoImage(file = "E:\\Circuit_Gif.gif")

    l2 = Label(master, image = bg)

    l2.place(x=0, y=0)

    l2.lower()

    b1 = Button(master,
                text="Rapid Touch",
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=rapid_touch,
                height=4,
                width=20,
                bg='#D83C16')

    b1.place(relx=0.5, rely=0.4, anchor=CENTER)

    b2 = Button(master,
                text="Sound Off",
                activebackground='#828C94',
                activeforeground='#761C1C',
                relief=RAISED,
                command=sound_off,
                height=4,
                width=20,
                bg='#D83C16')

    b2.place(relx=0.5, rely=0.7, anchor=CENTER)

    mainloop()

else:
    time.sleep(1)
    print("Program terminated")
