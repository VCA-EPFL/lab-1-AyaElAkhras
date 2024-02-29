import Vector::*;

typedef struct {
 Bool valid;
 Bit#(31) data;
 Bit#(4) index;
} ResultArbiter deriving (Eq, FShow);

function ResultArbiter arbitrate(Vector#(16, Bit#(1)) ready, Vector#(16, Bit#(31)) data);
 	Bool validity = False;
	Bit#(31) valid_data = 0;
	Bit#(4) valid_index = 0;

	for (Bit#(31) i = 0; i < 16; i = i + 1) begin
    	if(ready[i] == 1) begin
			validity = True;
			valid_data = data[i];
			valid_index = truncate(i);
		end
	end 
	return ResultArbiter{valid: validity, data : valid_data, index: valid_index};
endfunction

