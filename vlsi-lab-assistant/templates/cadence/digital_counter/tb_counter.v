`timescale 1ns/1ps
module tb_counter;
  reg clk = 0, rst = 1, en = 0;
  wire [7:0] q;
  integer errors = 0;

  counter dut (.clk(clk), .rst(rst), .en(en), .q(q));
  always #5 clk = ~clk;

  initial begin
    repeat (2) @(posedge clk);
    rst <= 0; en <= 1;
    repeat (10) @(posedge clk);
    #1 if (q !== 8'd10) begin errors = errors + 1; $display("FAIL: q=%0d expected 10", q); end
    en <= 0;
    repeat (3) @(posedge clk);
    #1 if (q !== 8'd10) begin errors = errors + 1; $display("FAIL: hold, q=%0d", q); end
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED (%0d errors)", errors);
    $finish;
  end
endmodule
