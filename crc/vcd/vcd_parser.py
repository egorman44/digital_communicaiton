from vcdvcd import VCDVCD
from pprint import PrettyPrinter
from crc import CrcCalculator, Configuration

def reverse_bits(num, width):
    print(f"{num:x}")
    i = width
    j = 0
    temp = 0

    while(i >= 0):
        temp |= ((num >> j)&1) << i
        i -=1
        j +=1

    return temp

def crc_calc(msg, init_crc):
    # CRC config
    config = Configuration(
        width=32,
        polynomial=0xF4ACFB13,
        init_value=init_crc,
        final_xor_value=0xFFFFFFFF,
        reverse_input=True,
        reverse_output=True,
    )
    calculator = CrcCalculator(config)
    return calculator.calculate_checksum(msg)

    
def check_pos(in_vect, pos):
    if((in_vect >> pos) & 1):
        return True
    else:
        return False

def fill_missing_times(io_dataIn, total_time_points):
    # Initialize the final list with the first element of the input list
    final_data = [io_dataIn[0]]

    # Iterate over the input list to find gaps
    for i in range(1, len(io_dataIn)):
        prev_time, prev_value = io_dataIn[i - 1]
        curr_time, curr_value = io_dataIn[i]

        # Add missing time points
        for t in range(prev_time + 1, curr_time):
            final_data.append((t, prev_value))

        # Append the current tuple
        final_data.append((curr_time, curr_value))

    # Fill up to the total time points if needed
    last_time, last_value = final_data[-1]
    for t in range(last_time + 1, total_time_points):
        final_data.append((t, last_value))
        
    return final_data

pp = PrettyPrinter()

vcd_path = "asep_crc_dump1.vcd"
vcd = VCDVCD(vcd_path)

cntr_cntr_name =  'dut.cntr_cntr_q[31:0]'

# Get a signal by human readable name.
signal = vcd[cntr_cntr_name]
print(signal)
tv = signal.tv
# Find all indexes where the second number of the tuple equals 10
cntr_cntr_val = 10197
cntr_cntr_val_bin_strm = bin(10197)[2:]
indexes = [index for index, (_, second) in enumerate(tv) if second == cntr_cntr_val_bin_strm]
start_time = tv[indexes[0]][0]
stop_time = 4000

TIME = 0
VAL = 1

io_dataIn_name = ['dut.io_dataIn_rev[3][7:0]', 'dut.io_dataIn_rev[2][7:0]', 'dut.io_dataIn_rev[1][7:0]', 'dut.io_dataIn_rev[0][7:0]']

# add missed time points
io_dataIn = []
final_data = []
for i in range(4):
    io_dataIn.append(vcd[io_dataIn_name[i]].tv)
    final_data.append(fill_missing_times(io_dataIn[i], 4096))
    
dataBitEnable = fill_missing_times(vcd['dut.io_dataBitEnable[3:0]'].tv, 4096)
io_init = fill_missing_times(vcd['dut.io_init'].tv, 4096)
print(f"type = {type(io_init)}")
#print(f" io_init = {io_init[3380][1]}")
qwerty = int('1',2)
pkt = []
init_crc = 0
crc_out = 0

for time in range (start_time, stop_time):
    word = []
    tkeep = int(dataBitEnable[time][VAL],2)
    init = int(io_init[time][VAL], 2)
    if(init):
        init_crc = 0xFFFFFFFF
    else:
        init_crc = reverse_bits(crc_out ^ 0xFFFFFFFF,31)
    #print(f"{time} = {tkeep} ")
    for i in range(len(final_data)):
        if(check_pos(int(dataBitEnable[time][VAL],2), i)):
            #print(f"{i}")
            pkt.append(int(final_data[i][time][VAL], 2))
            word.append(int(final_data[i][time][VAL], 2))
        #print(f"[{time}][{i}] = {int(final_data[len(final_data)-1-i][time][VAL], 2)}, {dataBitEnable[time]}")
    crc_out = crc_calc(word, init_crc)
    print(f"{time}: crc_out[] = {crc_out:x}")
    
