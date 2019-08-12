`timescale 1ns / 1ps



module Serial_clk_div

(

    input logic clk,        // 2^22 = 4.194304 MHz

    input logic reset,

    output logic clk_out,   // 2^13 = 8.192 kHz

    output logic [7:0] count

);



//  count to (clk/RTC_clk)/2 = 2^8 = 256

//logic [7:0] count;



always_ff @(posedge clk)

begin

    if (reset)

    begin

        count <= 8'd236;

        clk_out <= 1;

    end

    else

    begin

        if (count == 8'd255)

        begin

            count <= 0;

            clk_out <= ~clk_out;

        end

        else

            count++;

    end

end



endmodule