#!/usr/bin/env python
# 2013 Angelo Olivera <aolivera@gmail.com>

import os
import sys

def read_ports(file):
    f = open(file)
    Ports = {}
    while True:
        line = f.readline().strip()
        if not line: break
        port, process = line.split(',')
        Ports[int(port)] = process
    return Ports
    f.close()

def translate_port(Ports, port):
# input: port number
# output: port name (process) if found, otherwise port number
    if port in Ports:
        return Ports[port]
    else:
        return str(port)

def replace_ports(file):
    Ports = read_ports("port-process.csv")
    f = open(file)
    csv = []
    while True:
        line = f.readline().replace('"', '').strip()
        if not line: break
        csv = line.split(',')
        subst = []
        for entry in csv:
            try:
                subst.append(translate_port(Ports, int(entry)))
            except:
                subst.append(entry)
        print ",".join(subst)

def nmap_xml_to_csv(file):
    import xml.etree.ElementTree as ET

    tree = ET.parse(file)
    root = tree.getroot()

    for Ip in root.findall("./host/status[@state='up']/../address[@addrtype='ipv4']"):
      addr = Ip.attrib['addr']
      for Port in root.findall("./host/address[@addr='" + addr + "']/../ports/port"):
        print addr + "," + Port.attrib["portid"]

command = sys.argv[1]
testbed = sys.argv[2]
srcfile = sys.argv[3]

if command == "csv":
    replace_ports(srcfile)
elif command == "nmap":
    nmap_xml_to_csv(srcfile)

