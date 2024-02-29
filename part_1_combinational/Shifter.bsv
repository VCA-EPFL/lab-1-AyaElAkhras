import Vector::*;

typedef Bit#(16) Word;

function Vector#(16, Word) naiveShfl(Vector#(16, Word) in, Bit#(4) shftAmnt);
    Vector#(16, Word) resultVector = in; 
    for (Integer i = 0; i < 16; i = i + 1) begin
        Bit#(4) idx = fromInteger(i);
        resultVector[i] = in[shftAmnt+idx];
    end
    return resultVector;
endfunction


function Vector#(16, Word) barrelLeft(Vector#(16, Word) in, Bit#(4) shftAmnt);
    //return unpack(0);
    // Implementation of a left barrel shifter
    Vector#(16, Word) my_ret;

    Vector#(4, Vector#(16, Word)) stages;

    for(Integer i = 0; i < 4; i = i + 1) begin
        stages[i] = in;
    end

    if(shftAmnt[3] == 1)
        stages[3] = naiveShfl(in, fromInteger(8));

    for(Integer i = 2; i > -1; i = i - 1) begin
        // Each index represents 1 stage of Muxes and shftAmnt(i) is the select of this stage (0 or 1)
        if(shftAmnt[i] == 0)
            stages[i] = stages[i+1];
        else
            stages[i] = naiveShfl(stages[i+1], fromInteger(2**i));
    end

    my_ret = stages[0];

    return my_ret;
endfunction
