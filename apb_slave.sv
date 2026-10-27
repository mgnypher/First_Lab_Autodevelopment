// apb_slave

// feature update comment




module apb_slave
(
input pclk,                                 // синхросигнал
input presetn,                              // сигнал сброса (инверсный)
input [31:0] paddr,                         // адрес обращения
input [31:0] pwdata,                        // данные для записи
input psel,                                 // признак выбора устройства
input penable,                              // признак активной транзакции
input pwrite,                               // признак операции записи
output logic pready,                        // признак готовности от устройства
output logic pslverr,                       // признак ошибки при обращении
output logic [31:0] prdata                  // прочитанные данные
);

// Регистры слейва
logic [31:0] register_with_some_name; // 0x0
logic [31:0] reg_number;              // 0x4 (номер в списке / дата)
logic [31:0] reg_surname;             // 0x8 (Mish)
logic [31:0] reg_name;                // 0xC (Vlad)

// APB FSM
enum logic [1:0] {
APB_SETUP,
APB_W_ENABLE,
APB_R_ENABLE
} apb_st;

always @(posedge pclk)
if (!presetn)
begin
    prdata <= '0;
    pslverr <= 1'b0;
    pready <= 1'b0;
    register_with_some_name <= 32'h0;
    reg_number <= 32'h0;
    reg_surname <= 32'h0;
    reg_name <= 32'h0;
    apb_st <= APB_SETUP;
end
else
begin
    case(apb_st)
    APB_SETUP:
    begin: apb_setup_st
        // очистить prdata и ошибку
        prdata <= '0;
        pready <= 1'b0;
        pslverr <= 1'b0;

        // Переход в ENABLE при активном psel
        if (psel && !penable)
        begin
            if (pwrite == 1'b1)
                apb_st <= APB_W_ENABLE;
            else
                apb_st <= APB_R_ENABLE;
        end
    end: apb_setup_st

    APB_W_ENABLE:
    begin: apb_w_en_st
        if (psel && penable && pwrite)
        begin
            pready <= 1'b1;
            case (paddr[7:0])
            8'h0: begin
                // Логика: младший бит pwdata определяет значение
                if (pwdata[0] == 1'b0)
                begin
                    register_with_some_name <= 32'hAAAA_AAAA;
                    $display("APB WRITE 0x0: data=0x%h -> register=0xAAAAAAAA", pwdata);
                end
                else
                begin
                    register_with_some_name <= 32'h5555_5555;
                    $display("APB WRITE 0x0: data=0x%h -> register=0x55555555", pwdata);
                end
            end
            8'h4: begin
                reg_number <= pwdata;
                $display("APB WRITE 0x4 (number/date): data=0x%h", pwdata);
            end
            8'h8: begin
                reg_surname <= pwdata;
                $display("APB WRITE 0x8 (surname): data=0x%h", pwdata);
            end
            8'hC: begin
                reg_name <= pwdata;
                $display("APB WRITE 0xC (name): data=0x%h", pwdata);
            end
            default:
            begin
                pslverr <= 1'b1;
                $display("APB WRITE ERROR: bad address 0x%h", paddr);
            end
            endcase
            apb_st <= APB_SETUP;
        end
    end: apb_w_en_st

    APB_R_ENABLE:
    begin: apb_r_en_st
        if (psel && penable && !pwrite)
        begin
            pready <= 1'b1;
            case (paddr[7:0])
            8'h0: begin
                prdata[31:0] <= register_with_some_name[31:0];
                $display("APB READ 0x0: data=0x%h", register_with_some_name);
            end
            8'h4: begin
                prdata[31:0] <= reg_number[31:0];
                $display("APB READ 0x4: data=0x%h", reg_number);
            end
            8'h8: begin
                prdata[31:0] <= reg_surname[31:0];
                $display("APB READ 0x8: data=0x%h", reg_surname);
            end
            8'hC: begin
                prdata[31:0] <= reg_name[31:0];
                $display("APB READ 0xC: data=0x%h", reg_name);
            end
            default:
            begin
                pslverr <= 1'b1;
                $display("APB READ ERROR: bad address 0x%h", paddr);
            end
            endcase
            apb_st <= APB_SETUP;
        end
    end: apb_r_en_st

    default:
    begin
        pslverr <= 1'b1;
    end
    endcase
end

endmodule