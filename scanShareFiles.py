#!/usr/bin/python
#  -*- coding: utf-8 -*-

"""
scanShareFiles

    scan a folder and produce JSON stream of attributes foreach file found

See the usage method for more information and examples.

"""
# Imports: native Python
import argparse
import datetime
import grp
import hashlib
import json
import logging
import logging.handlers
import os
import os.path
from pathlib import Path
import pwd
import random
import sys
import traceback
from encodings.aliases import aliases
from uuid import uuid1

# 3rd party imports
#from confluent_kafka import Producer, Consumer, KafkaError, OFFSET_BEGINNING, OFFSET_END, OFFSET_STORED, OFFSET_INVALID


BLKSIZE = 131072


#-----------------------------------------------------------------------------
def usage():
    """
        Description:
    """
    examples = """

Usage:
    $progname <folder> <folder> <folder>

"""
    return examples


#-----------------------------------------------------------------------------
def file_info(file, data):

    data['file'] = file

    data['name'] = os.path.basename(file)
    data['folder'] = os.path.dirname(file)
    data['depth'] = file.count('/')

    for key in ['dir_count', 'file_count', 'size']:
        if key in data.keys():
            del data[key]

    try:
        p = Path(file)
        fstat = p.stat(follow_symlinks=True)
        data['blocks'] = fstat.st_blocks
        data['block_size'] = fstat.st_blksize
        data['device'] = fstat.st_dev
        data['device_type'] = fstat.st_rdev
        data['gid'] = fstat.st_gid
        if p.group():
            data['group_name'] = p.group()
        elif 'group_name' in data.keys():
            del data['group_name']
        data['hard_links'] = fstat.st_nlink
        data['inode'] = fstat.st_ino
        data['last_access'] = int(fstat.st_atime)
        data['last_access_time'] = zulu_timestamp(fstat.st_atime)
        data['last_modified'] = int(fstat.st_mtime)
        data['last_modified_time'] = zulu_timestamp(fstat.st_mtime)
        data['last_status_change'] = int(fstat.st_ctime)
        data['last_status_change_time'] = zulu_timestamp(fstat.st_ctime)
        data['mode_8'] = oct(fstat.st_mode)
        data['size'] = fstat.st_size
        data['type'] = file_type(p)
        data['uid'] = fstat.st_uid
        if get_username(fstat.st_uid):
            data['user_name'] = get_username(fstat.st_uid)
        elif 'user_name' in data.keys():
            del data['user_name']

    except ValueError:
        for key in ['blocks', 'block_size', 'device', 'device_type', 'gid', 'group_name', 'hard_links', 'inode', 'last_access', 'last_access_time', 'last_modified', 'last_modified_time', 'last_status_change', 'last_status_change_time', 'mode_8', 'mode_x', 'size', 'type', 'uid', 'user_name']:
            if key in data.keys():
                del data[key]

    if os.path.islink(file):
        if os.path.exists(file):
            data['reference'] = os.path.realpath(file)
            data['isvalid'] = 'true'
        else:
            data['reference'] = os.path.realpath(file)
            data['isvalid'] = 'false'
        return data

    for key in ['reference', 'isvalid']:
        if key in data.keys():
            del data[key]

    if not os.path.isdir(file):
        data['sha256'] = sha256(file, fstat.st_size)

    return data

#-----------------------------------------------------------------------------
def get_groupname(gid):
    """
    Returns the name of the group corresponding to the given group ID (gid).
    If the group ID is not found, None is returned.
    """
    group_info = grp.getgrgid(gid)
    return group_info[0] if group_info else None

#-----------------------------------------------------------------------------
def get_username(uid):
    username = None
    try:
        username = pwd.getpwuid(uid)[0]
    except KeyError:
        pass
    return username


#-----------------------------------------------------------------------------
def file_type(p):
    if p.is_block_device():
        return "block device"
    if p.is_char_device():
        return "character device"
    if p.is_dir():
        return "directory"
    if p.is_fifo():
        return "FIFO/pipe"
    if p.is_symlink():
        return "symlink"
    if p.is_file():
        return "regular file"
    if p.is_socket():
        return "socket"
    return "unknown"

#-----------------------------------------------------------------------------
def sha256(file_path, block_size):
    if block_size <= 0:
        return ''

    sha = hashlib.sha256()
    with open(file_path, mode='rb') as file:
        while True:
            chunk = file.read(block_size)
            if not chunk:
                break
            sha.update(chunk)

    return sha.hexdigest()

#-----------------------------------------------------------------------------
def generate_insecure_uuid() -> str:
    """
    Generate an insecure UUID.

    This function generates a UUID using a random number of 48 bits
    and returns the UUID as a string.

    Returns:
        str: The generated insecure UUID.
    """
    random_num = random.getrandbits(48)
    return str(uuid1(random_num))

#-----------------------------------------------------------------------------
def zulu_timestamp(tstamp):
    """
    Convert a timestamp to a Zulu timestamp string format.

    Args:
        tstamp (float): The timestamp to convert.

    Returns:
        str: The Zulu timestamp string in the format "%Y-%m-%dT%I:%M:%S.%fZ".
    """
    # Convert the timestamp to a datetime object
    dt = datetime.datetime.fromtimestamp(tstamp)

    # Format the datetime object as a Zulu timestamp string
    zulu_timestamp_str = dt.strftime("%Y-%m-%dT%I:%M:%S.%fZ")

    return zulu_timestamp_str


#-----------------------------------------------------------------------------
class GetArgs:

    def __init__(self):
        """
        Description:
            Parse the arguments given on command line.

        Returns:
            Namespace containing the arguments to the command. The object holds the argument
            values as attributes, so if the arguments dest is set to "myoption", the value
            is accessible as args.myoption
        """
        # parse any command line arguments
        p = argparse.ArgumentParser(description='scan one or more files or folders and output JSON file data',
                                    epilog=usage(),
                                    formatter_class=argparse.RawDescriptionHelpFormatter)
        p.add_argument('-k', '--kafka', action='store_true', help='send to kafka')
        p.add_argument('-t', '--topic', required=False, default=None, type=str, help='kafka topic to send to')
        p.add_argument('-s', '--servers', required=False, default=None, type=str, help='kafka brokers')
        p.add_argument('-f', '--file', required=False, default='files.json', type=str, help='name of file to save JSON')
        p.add_argument('dirs', nargs=argparse.REMAINDER, help='one or more files or folders')

        args = p.parse_args()
        self.dirs = args.dirs
        self.kafka = args.kafka
        self.topic = args.topic
        self.servers = args.servers
        self.file = args.file


    def validate_options(self):
        """
        Description:
            Validate the correct arguments are provided and that they are the correct type

        Raises:
            ValueError: If request_type or request_status are not one of the acceptable values

        """
        if self.kafka:
            if self.servers is None:
                self.servers = os.getenv('KAFKA_BOOTSTRAP_SERVERS')
            if self.servers is None:
                raise ValueError('No kafka servers defined')
            if self.topic is None:
                raise ValueError('No kafka topic defined')

        if len(self.dirs) == 0:
            raise ValueError('No directories or files defined')


#-----------------------------------------------------------------------------
class FileProducer(object):
    def __init__(self, filename, topic = ''):
        self.filename = filename
        self.op_file = open(filename, 'wt')
        self.topic = topic

    def close(self):
        self.op_file.close()

    def produce(self, value=None):
        try:
            my_json = json.dumps(value)
            self.save(my_json)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            traceback.print_exception(exc_type, exc_value, exc_traceback, limit=2, file=sys.stdout)
            for k in value:
                print (f"   {k}: ")


    def save(self, info):
        self.op_file.write(info + "\n")
        self.op_file.flush()



#-----------------------------------------------------------------------------
class KafkaProducer(object):
    def __init__(self, server, topic):
        # bootstrap.servers  - A list of host/port pairs to use for establishing the initial connection to the Kafka cluster
        # client.id          - An id string to pass to the server when making requests
        self.topic = topic

    def produce(self, value=None, key=None):
        # Convert value and key to utf-8 format
        json_objects = json.loads(value)
        json_objects['timestamp'] = zulu_timestamp()
        json_objects['uuid'] = generate_insecure_uuid()

        input_data = dict()
        input_data["topic"] = self.topic

        input_data["value"] = json.dumps(json_objects)
        input_data["key"] = key

        self.logger.debug("Input Data to produce: \n %s" % input_data)
        self.kafka.produce(**input_data)
        # flush() - Wait for all messages in the Producer queue to be delivered
        self.kafka.flush()

    def close(self):
        self.kafka.close()


#-----------------------------------------------------------------------------
class ScanShareFiles:

    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG)

        # create file handler which logs even debug messages
        fh = logging.FileHandler('version_updater.log')
        fh.setLevel(logging.DEBUG)

        # create console handler with a higher log level
        ch = logging.StreamHandler()
        ch.setLevel(logging.ERROR)

        # create formatter and add it to the handlers
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        fh.setFormatter(formatter)
        ch.setFormatter(formatter)

        # add the handlers to the logger
        self.logger.addHandler(fh)
        self.logger.addHandler(ch)

        self.producer = None
        self.op_file = None
        self.dirs = dict()
        self.changes = 0
        self.file_count = 0
        self.dir_count = 0


    def main(self, cmdargs):
        args = GetArgs()
        args.validate_options()
        self.args = args
        args.validate_options()
        self.args = args
        if args.kafka:
            self.producer = KafkaProducer(args.servers, args.topic)
        else:
            self.producer = FileProducer(args.file, args.topic)
        self.data = dict()

        for dir in args.dirs:
            print('dirs:  '+dir)
            self.produce_data(dir)
        self.producer.close()
        self.create_summary()

    def create_summary(self):
        # TODO
        pass

    def produce_data(self, basedir):
        file_count = 0
        dir_count = 0
        sha = hashlib.sha256()
        size = 0

        for name in os.listdir(basedir):
            if name == '#recycle':
                continue

            try:
                file = os.path.join(basedir, name)

                if os.path.isdir(file):
                    dir_count += 1
                    self.produce_data(file)

                else:
                    file_count += 1
                    file_info(file, self.data)
                    self.producer.produce(self.data)

                if 'size' in self.data.keys():
                    size += self.data['size']

                if 'sha256' in self.data.keys():
                    sha.update(self.data['sha256'])

            except Exception:
                continue


        file_info(basedir, self.data)
        self.data['size'] = size
        self.data['file_count'] = file_count
        self.data['dir_count'] = dir_count
        self.data['sha256'] = sha.hexdigest()
        self.producer.produce(self.data)

        print ('   detected {} dirs and {} files on {}'.format(dir_count, file_count, basedir))



#-----------------------------------------------------------------------------

# ### ----- M A I N   D R I V E R   C O D E ----- ### #

if __name__ == "__main__":
    out = ScanShareFiles()
    sys.exit(out.main(sys.argv[1:]))
