import math

class PolyDivision:
    def __init__(self, message, message_degree, poly, poly_degree, init = 0, res_xor = 0, dbg = 1):
        self.message        = message
        self.message_degree = message_degree
        self.poly_degree    = poly_degree
        self.enc_message    = message *(2**self.poly_degree)
        self.enc_message    = init * (2**(self.message_degree)) ^ self.enc_message
        self.poly           = poly + (2**self.poly_degree)
        self.iteration      = 0
        self.dbg            = dbg
        print("POLY    : {}".format(hex(self.poly)))
        print("MESSAGE : {}".format(hex(self.enc_message)))
        print(f"DBG : {self.dbg}")
        self.divide(self.enc_message, self.dbg)
        
    def divide(self, divident, dbg):
        # Skip log2 eval if divident is 0
        if(divident):
            divident_degree = int(math.floor(math.log2(divident)))
        else:
            divident_degree = 0
        if(divident_degree >= self.poly_degree):
            diff_degree     = divident_degree - self.poly_degree
            poly_Xn         = self.poly * (2**diff_degree)
            xor             = divident ^ poly_Xn
            if(dbg):
                print("Iteration {}:".format(self.iteration))
                print(hex(divident))
                print(hex(poly_Xn))
                # Need to calc what number of zeros
                # should be added to xor value to
                # display it propely. Keep in mind
                # that values are displayed in hex
                xor_hex_msb = int((int(math.floor(math.log2(xor)))) / 4) + 1
                xor_hex_diff   = int(math.floor(divident_degree / 4)) +1 - xor_hex_msb
                xor_s      = '0x' + '0'*xor_hex_diff + f'{xor:x}'
                print(xor_s)
            self.iteration +=1
            self.divide(xor,self.dbg)
        else:
            print("CRC: "+ hex(divident))
            

poly        = 0x4C11DB7
poly_degree = 32
message     = 0xBB
message_degree = 8                                      
init        = 0x135B56FA

PolyDiv = PolyDivision(message, message_degree, poly, poly_degree, init,0, 1)
