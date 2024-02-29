import Vector::*;
import BRAM::*;

// Time spent on VectorDot: __~1 hour__

// Please annotate the bugs you find.

interface VD;
    method Action start(Bit#(8) dim_in, Bit#(2) i);
    method ActionValue#(Bit#(32)) response();
endinterface

(* synthesize *)
module mkVectorDot (VD);
    BRAM_Configure cfg1 = defaultValue;
    cfg1.loadFormat = tagged Hex "v1.hex";
    BRAM1Port#(Bit#(8), Bit#(32)) a <- mkBRAM1Server(cfg1);
    BRAM_Configure cfg2 = defaultValue;
    cfg2.loadFormat = tagged Hex "v2.hex";
    BRAM1Port#(Bit#(8), Bit#(32)) b <- mkBRAM1Server(cfg2);

    Reg#(Bit#(32)) output_res <- mkReg(unpack(0));

    Reg#(Bit#(8)) dim <- mkReg(0);

    Reg#(Bool) ready_start <- mkReg(False); 
    Reg#(Bit#(8)) pos_a <- mkReg(unpack(0));
    Reg#(Bit#(8)) pos_b <- mkReg(unpack(0));
    Reg#(Bit#(8)) pos_out <- mkReg(unpack(0));
    Reg#(Bool) done_all <- mkReg(False);
    Reg#(Bool) done_a <- mkReg(False);
    Reg#(Bool) done_b <- mkReg(False);
    Reg#(Bool) req_a_ready <- mkReg(False);
    Reg#(Bool) req_b_ready <- mkReg(False);

    Reg#(Bit#(2)) i <- mkReg(0);


    rule process_a (ready_start && !done_a && !req_a_ready);
        a.portA.request.put(BRAMRequest{write: False, // False for read
                            responseOnWrite: False,
                            address: zeroExtend(pos_a),
                            datain: ?});
        $display("pos_a in process_a AFTER portA request: %d", pos_a);
        if (pos_a < dim*zeroExtend(i+1) - 1)  // Bug: Should offset by the dim each time
            pos_a <= pos_a + 1;
        else begin
            done_a <= True;
        end

       req_a_ready <= True;

    endrule

    rule process_b (ready_start && !done_b && !req_b_ready);
        b.portA.request.put(BRAMRequest{write: False, // False for read
                responseOnWrite: False,
                address: zeroExtend(pos_b),
                datain: ?});

        if (pos_b < dim*zeroExtend(i+1) - 1)  // Bug: Should offset by the dim each time
            pos_b <= pos_b + 1;
        else begin
            done_b <= True;
        end
    
        req_b_ready <= True;
    endrule

    rule mult_inputs (req_a_ready && req_b_ready && !done_all);
        $display("Hii from inside the mult_inputs rule");

        let out_a <- a.portA.response.get();
        let out_b <- b.portA.response.get();

        output_res <= output_res + (out_a*out_b);  // Bug: was missing the addition
        pos_out <= pos_out + 1;

        $display("pos_out from inside mult_inputs is %d", pos_out);
        
        if (pos_out == dim-1) begin   
            done_all <= True;
        end


        req_a_ready <= False;
        req_b_ready <= False;
    endrule



    method Action start(Bit#(8) dim_in, Bit#(2) i_in) if (!ready_start);
        $display("Hii from inside the method start");
    
        ready_start <= True;
        dim <= dim_in;
        done_all <= False;
        pos_a <= dim_in*zeroExtend(i_in);  // Bug: Used to multiply by i which is outdated every new test
        pos_b <= dim_in*zeroExtend(i_in);  // Bug: Used to multiply by i which is outdated every new test
        done_a <= False;
        done_b <= False;
        pos_out <= 0;
        i <= i_in;

        output_res <= 0;  // Bug: reset the output with every new input

    endmethod

    method ActionValue#(Bit#(32)) response() if (done_all);
        $display("Hi from inside response");
        
        ready_start <= False;  // Bug: Must add this line to ensure that it triggers start again to load a new set of data
        return output_res;
    endmethod

endmodule


