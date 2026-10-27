module TB;

logic pclk;
logic presetn;
logic psel;
logic penable;
logic pwrite;
logic [31:0] paddr;
logic [31:0] pwdata;
wire [31:0] prdata;
wire pready;
wire pslverr;

parameter p_device_offset = 32'h7000_0000;

logic [31:0] address;
logic [31:0] data_to_device;
logic [31:0] data_from_device;

apb_slave DUT
(
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

task apb_write(input [31:0] addr, input [31:0] data);
    begin
        wait ((penable==0) && (pready == 0));
        @(posedge pclk);
        psel <= 1'b1;
        paddr[31:0] <= addr[31:0];
        pwdata[31:0] <= data[31:0];
        pwrite <= 1'b1;
        @(posedge pclk);
        penable <= 1'b1;
        @(posedge pclk);
        wait (pready == 1'b1);
        @(posedge pclk);
        psel <= 1'b0;
        penable <= 1'b0;
        pwrite <= 1'b0;
        @(posedge pclk);
    end
endtask

task apb_read(input [31:0] addr, output [31:0] data);
    begin
        wait ((penable==0) && (pready == 0));
        @(posedge pclk);
        psel <= 1'b1;
        pwrite <= 1'b0;
        paddr[31:0] <= addr[31:0];
        @(posedge pclk);
        penable <= 1'b1;
        @(posedge pclk);
        wait (pready == 1'b1);
        @(posedge pclk);
        data[31:0] <= prdata[31:0];
        psel <= 1'b0;
        penable <= 1'b0;
        @(posedge pclk);
    end
endtask

always
#10ns pclk = ~pclk;

initial
begin
    pclk = 0;
    presetn = 1'b1;
    psel = '0;
    penable = '0;
    pwrite = '0;
    paddr = '0;
    pwdata = '0;

    repeat (5) @(posedge pclk);
    presetn = 1'b0;
    repeat (5) @(posedge pclk);
    presetn = 1'b1;
    repeat (5) @(posedge pclk);

    // 0x0: номер в списке = 5 (младший бит = 1 -> ляжет 0x55555555)
    apb_write(p_device_offset + 0, 32'd5);

    // 0x4: дата 27.10.2026 -> BCD 0x27102026
    apb_write(p_device_offset + 4, 32'h2710_2026);

    // 0x8: "Mish" -> 0x4D697368
    apb_write(p_device_offset + 8, 32'h4D69_7368);

    // 0xC: "Vlad" -> 0x566C6164
    apb_write(p_device_offset + 32'hC, 32'h566C_6164);

    // Чтение и проверка
    apb_read(p_device_offset + 0, data_from_device);
    $display("READ 0x0: 0x%h (expect 0x55555555, т.к. младший бит 5 = 1)", data_from_device);

    apb_read(p_device_offset + 4, data_from_device);
    $display("READ 0x4: 0x%h (expect 0x27102026)", data_from_device);

    apb_read(p_device_offset + 8, data_from_device);
    $display("READ 0x8: 0x%h (expect 0x4D697368 = 'Mish')", data_from_device);

    apb_read(p_device_offset + 32'hC, data_from_device);
    $display("READ 0xC: 0x%h (expect 0x566C6164 = 'Vlad')", data_from_device);

    repeat (10) @(posedge pclk);
    $stop();
end

initial
begin
$monitor("APB IF state: PENABLE=%b PREADY=%b PADDR=0x%h PWDATA=0x%h PRDATA=0x%h", penable, pready, paddr, pwdata, prdata);
end

endmodule