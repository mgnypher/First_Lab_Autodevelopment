module top;

logic pclk, presetn, psel, penable, pwrite;
logic [31:0] paddr, pwdata, prdata;
logic pready, pslverr;

apb_slave dut (
    .pclk(pclk),
    .presetn(presetn),
    .paddr(paddr),
    .pwdata(pwdata),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .pready(pready),
    .pslverr(pslverr),
    .prdata(prdata)
);

endmodule