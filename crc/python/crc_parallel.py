import numpy as np

class BitOperation:
    def __init__(self, in_vect):
        self.in_vect = in_vect
        self.int_val = 0
    def check_pos(self, pos):
        if((self.in_vect >> pos) & 1):
            return True
        else:
            return False
        
    def bin_to_int(self, pos):
        self.int_val = (1 << pos) | self.int_val
        
#poly = 0xF4ACFB13
poly = 0x4C11DB7
poly_degree    = 32
message_degree = 32

#poly = 0x7
#poly_degree    = 8
#message_degree = 8


#poly           = 0b100101
#poly_degree    = 5
#message_degree = 4

encoded_degree = message_degree + poly_degree

poly        = poly + (2**poly_degree)

# Create A and A_a:
# A - matrix for S[i+1] computation
# A_a will hold the power of A matrixes

A = np.zeros([poly_degree,poly_degree], dtype=int)
A_a = []

print("POLY = {}".format(hex(poly)))
BitOp = BitOperation(poly)

# Next state value S[i+1] depends on the value in poly position:
# 0 - then S[i+1] depends only on S[i]
# 1 - then S[i+1] = S[i] ^ S[poly_degree-1]
# and if pos == 0, then instead of S[i] we take D[message_degree-1]

for indx in range(poly_degree):
    if(indx):
        A[indx,indx-1] = 1
    if(BitOp.check_pos(indx)):
        A[indx,poly_degree-1] = 1
        if(indx):
            print("S{}[i+1] = S{}[i] ^ S{}[i]".format(indx, poly_degree-1, indx -1))
        else:
            print("S{}[i+1] = S{}[i] ^ D[{}]".format(indx, poly_degree-1, message_degree-1))
    else:
        if(indx):
            print("S{}[i+1] = S{}[i]".format(indx, indx-1))
        else:
            print("S0[i+1] = D[{}]".format(message_degree-1))

print(f"A matrix:")
for row in range(0, A.shape[0]):
    print(f"S{row}[i+1] = {A[row]}")

# Eval power of A
for indx in range(encoded_degree):
    if(not indx):
        A_a.append(A)
    else:
        A_a.append(np.dot(A_a[indx-1],A_a[0]))
        # A_a must container [1,0] only
        for iy, ix in np.ndindex(A_a[indx].shape):
            A_a[indx][iy,ix] = A_a[indx][iy,ix] % 2

###########################            
# S0 - dependence on S0 state
# D  - data dependence
###########################

D = np.zeros([poly_degree,message_degree], dtype=int)
D_indx = 0
S0 = np.zeros([poly_degree,poly_degree], dtype=int)

# 0 ... 39(40)
# poly_degree   = 32
# poly_degree-1 = 31
# [32:39] -> [0:7]

# 0 ... 8(9)
# poly_degree   = 5
# poly_degree-1 = 4
# [5:8] -> [0:3]

for indx in range(len(A_a)):
    if(indx >= poly_degree-1):
        # Last A is resoponsible for initial state
        if(indx == len(A_a)-1):
            print(f"S0 = A_a[{indx}]")
            S0 = A_a[indx]
        else:
            print(f"A_a[{indx}]*D[{indx}]")
            D[:,D_indx] = A_a[indx][:,0]
            D_indx += 1
            print(A_a[indx][:,0])
            print("\n")

crc_l = []

for row in range(0, D.shape[0]):
    crc = ""
    for col in range(0, D.shape[1]):
        if(D[row,col]):
            # If crc is not empty then add XOR operator
            if(crc):
                crc = f"{crc} ^ D[{col}]"
            else:
                crc = f"D[{col}]"
    crc = f"S[{row}] = {crc}"
    crc_l.append(crc)
    
for line in crc_l:
    print(line + ';')

for row in range(0, S0.shape[0]):    
    print(f"S0[{row}]" + str(S0[row]))
    
################
# Eval CRC
################

#init = 0x12345678
init = 0x0
data_ex = 0x0000_008F
data_init_ex = data_ex ^ init
DataOp = BitOperation(data_init_ex)
data_np = np.zeros([1,message_degree], dtype=int)

for col in range(0, data_np.shape[1]):
    if(DataOp.check_pos(col)):
        data_np[0,col] = 1

print(data_np.T)

print(D)
crc_val = np.dot(D,data_np.T)
crc_val = crc_val.T
    
for col in range(0, crc_val.shape[1]):
    crc_val[0,col] = crc_val[0,col] % 2
    if(crc_val[0,col]):        
        DataOp.bin_to_int(col)

print(f"data_init_ex {hex(data_init_ex)}")
print(crc_val)
print(hex(DataOp.int_val))
