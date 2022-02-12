// Engineer: Max van der Merwe
// Create Date: 17/03/2021
// Description: Manual Eye Scan using DRP interface to GTX transceiver
// Interfaces with UART and labview to operate and readout eye scan data
// Adapted from: https://www.xilinx.com/support/answers/64098.html

module eyeScan
    (
        input             CLK,
        input             TXFSMRESETDONE,
        input             RXFSMRESETDONE,
        input             SOFRST,
        input [15:0]      DRPDO,
        input             DRPRDY,
        output reg [8:0]  DRPADDR,
        output reg        DRPWE,
        output reg        DRPEN,
        output reg [15:0] DRPDI,
        input   RunScan,
        output  ScanComplete,
        input   GetData_eye_req,
        output  GetData_eye_rdy,
        input   GetData_eye_nxt,
        output  GetData_eye_cmplt,
        input  [4:0]   Max_Prescale,
        output [991:0] GetData_eye_vertical,
        output [991:0] GetData_eye_horizontal,
        output [991:0] GetData_eye_samples,
        output [991:0] GetData_eye_errors
    );
    
    // Signals used in running the eye scan
    reg [4:0]   state;
    reg [3:0]   status;
    reg [15:0]  errors;
    reg [15:0]  pixelCount;
    reg [10:0]  horz;
    reg [6:0]   vert;
    reg [15:0]  samples;
    reg [8:0]   drpAddr;
    reg         drpWe;
    reg         drpEn;
    reg [15:0]  drpDi;
    reg         drpDone;
    
    reg GetData_Buffered = 0;
    reg GetData_cmplt = 0;
    
    reg [991:0] VertData;
    reg [991:0] HorzData;
    reg [991:0] SampleData;
    reg [991:0] ErrorData;
    
    // The number of steps is currently compared to a hardcoded threshold
    // Plan to make the number of steps dynamic based on step size
    // vStepThreshold = floor(127/vstepSize) from 0 to +max, and from 0 to -max
    // hStepThreshold depends on value of RXOUT_DIV (RXOUT_DIV = 1 -> threshold = 32)
    reg [8:0]   hsteps;
    reg [8:0]   vsteps;
    
    // Hard coding initial values for now, plan to set these values through UART
    reg [5:0]  hstepSize = 1;
    reg [6:0]  vstepSize = 1;
    reg [15:0] minErrorCount = 3;
    reg signed [3:0]   stepPrescale = 3;
    reg signed [4:0]   nextPrescale;
    reg signed [4:0]   prescale = 0;
    reg [6:0]  vertValue;
    reg [10:0] horzValue;
    reg nextScan = 0;
    reg [5:0]  DataCntr = 0;
    reg bramRead = 0;
    reg bramRdy = 0;
    reg UTsign = 0;
    reg go;
    reg ScanCompleted = 0;
    reg waitNext = 0;
    reg [11:0]  index = 0;
    reg [7:0] rowNum = 0;
    reg GetData_eye_nxt_old = 0;
    reg GetData_eye_req_old = 0;
    reg RunScan_old = 0;
    reg beginReadout = 0;
    
    // BRAM signals
    reg clka;
    reg rsta;
    reg [0:0]   wea;
    reg [17:0]  addra;
    reg [15:0]  dina;
    wire [127:0] douta;
    wire rsta_busy;
    reg ilaClk;
    parameter waitGoCmd = 0, run = 1, waitStart = 2, waitComplete = 3, getErrors = 4, storeErrors = 5,getSamples=6,storeSamples=7,rstCmd=8,waitRstCmd=9,updateHorizontal=10,updateVertical =11, waitRun = 12, waitHorizontal=13, waitVertical=14,testStart=15,testComplete = 16,storeData = 17, setInitialVertical = 18, waitInitialVertical = 19, checkGearshift = 20, writeNewPrescale = 21, waitNewPrescale = 22, toggleUTsign = 23, writeVert = 24, waitBRAM = 25;
    
    assign GetData_eye_rdy = GetData_Buffered;
    assign GetData_eye_vertical = VertData;
    assign GetData_eye_horizontal = HorzData;
    assign GetData_eye_samples = SampleData; 
    assign GetData_eye_errors = ErrorData;
    assign ScanComplete = ScanCompleted;
    assign GetData_eye_cmplt = GetData_cmplt;
    
    blk_mem_gen_0 bram (
      .clka(CLK),            // input wire clka
      .rsta(rsta),            // input wire rsta
      .wea(wea),              // input wire [0 : 0] wea
      .addra(addra),          // input wire [17 : 0] addra
      .dina(dina),            // input wire [15 : 0] dina
      .douta(douta),          // output wire [127 : 0] douta
      .rsta_busy(rsta_busy)  // output wire rsta_busy
    );
        
    always @ (posedge CLK) begin
        if (SOFRST || (RunScan_old && !RunScan)) begin
            rsta <= 1;
            index <= 0;
            GetData_cmplt <= 0;
            ScanCompleted <= 0;
            state <= waitGoCmd;
        end
        else
        case (state)
            waitGoCmd: begin
                wea <= 1'b0;
                pixelCount <= 0;
                prescale <= 0;
                nextPrescale <= prescale;
                drpWe <=0;
                drpEn <= 0;
                drpAddr <= 0;
                drpDi <= 0;
                hsteps <= 0;
                vsteps <= 0;
                horz <= 11'b00000100000; 
                vert <= 7'b1111111; //7'b1111100 for 124 (stepsize 4)
                vertValue <= 7'b1111111;
                UTsign <= 0;
                rsta <= 0;
                rowNum <= 0;
                if (go) begin
                   state <= setInitialVertical;
                   wea <= 1'b0;
                   go <= 0;
                   GetData_cmplt <= 0;
                end
                else begin
                    if (RunScan && !RunScan_old) begin
                        ScanCompleted <= 0;
                        go <= 1;
                    end
                    else
                        go <= 0;
                    state<=waitGoCmd;
                end
            end
            setInitialVertical: begin
                addra <= (pixelCount * 8) + (UTsign * 4);
                dina <= {prescale,2'b00,UTsign,1'b0,vert};
                drpEn <=0;
                drpDi <= {prescale,2'b00,UTsign,1'b0,vert};
                vertValue <= vert;
                vert <= vert - vstepSize;
                vsteps <= vsteps+1;
                drpAddr <= 9'h03B;
                drpWe <= 1;
                wea <= 1'b1;
                state <= waitInitialVertical;
            end
            waitInitialVertical:begin
                drpWe <= 0;
                drpEn <=0;
                wea <= 1'b0;
                if (DRPRDY)
                    state <= updateHorizontal;
                else
                    state <= waitInitialVertical;
            end
            updateHorizontal: begin
                drpEn <=0;
                if (hsteps < 65) begin
                    addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520) + 1;
                    if (hsteps > 32) begin
                        dina <= horz | 16'h0800;
                        horz <= horz - hstepSize;
                        drpDi <= horz | 16'h0800;
                        hsteps <= hsteps + 1;
                    end 
                    else begin
                        dina <= horz;
                        horz <= horz - hstepSize;
                        drpDi <= horz;
                        hsteps <= hsteps + 1;
                   end
                   wea <= 1'b1;
                end
                else begin
                    dina <= 16'b0000000000100000;
                    drpDi <= 16'b0000000000100000;
                    horz <= 11'b00000100000;
                    hsteps <= 0;
                    wea <= 1'b0;
                end
                drpAddr <= 9'h03C;
                drpWe <= 1;
                state <= waitHorizontal;
            end
            waitHorizontal:begin
                drpEn <=0;
                drpWe <= 0;
                wea <= 1'b0;
                if (DRPRDY) begin
                    if (hsteps == 9'd0) begin
                        if (UTsign == 1) begin
//                            UTsign <= 1;
                            state <= toggleUTsign;
                        end
                        else begin
//                            UTsign <= 0;
                            state <= updateVertical;
                        end
                    end
                    else
                        state <= run;
                    end
                else
                    state <= waitHorizontal;
            end
            updateVertical: begin
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520);
                vertValue <= vert;
                if (vsteps < 255 ) begin    // 63 for step size 4
                    vsteps <= vsteps + 1;
                    drpEn <=0;
                    if (vsteps > 126) begin  // 30 for step size 4
                        dina <= {prescale,2'b00,UTsign,1'b1,vert};
                        vert <= vert + vstepSize;
                        drpDi <= {prescale,2'b00,UTsign,1'b1,vert};
                    end
                    else begin
                        dina <= {prescale,2'b00,UTsign,1'b0,vert};
                        vert <= vert - vstepSize;
                        drpDi <= {prescale,2'b00,UTsign,1'b0,vert};
                    end
                    drpAddr <= 9'h03B;
                    drpWe <= 1;
                    wea <= 1'b1;
                    state <= waitVertical;
                end
                else begin
                    ScanCompleted <= 1;
                    state <= waitGoCmd;
                end
            end
            toggleUTsign: begin
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520);
                if (vsteps-1 < 255 ) begin // 63 stepsize 4
                    drpEn <=0;
                    if (vsteps-1 > 126) begin // 30 stepsize 4
                        dina <= {prescale,2'b00,UTsign,1'b1,vertValue};
                        drpDi <= {prescale,2'b00,UTsign,1'b1,vertValue};
                    end
                    else begin
                        dina <= {prescale,2'b00,UTsign,1'b0,vertValue};
                        drpDi <= {prescale,2'b00,UTsign,1'b0,vertValue};
                    end
                    drpAddr <= 9'h03B;
                    drpWe <= 1;
                    wea <= 1'b1;
                    state <= waitVertical;
                end
                else begin
                    ScanCompleted <= 1;
                    state <= waitGoCmd;
                end
            end
            waitVertical:begin
                drpWe <= 0;
                drpEn <=0;
                wea <= 1'b0;
                if (DRPRDY)
                    state <= run;
                else
                    state <= waitVertical;
            end
            run: begin
                drpEn <=0;
                drpAddr <= 9'h03D;  //Set address to ES_CONTROL
                drpDi <= 16'hE301;  // Set run bit and eye Scan enable bit
                drpWe <= 1;
                state <= waitRun;
            end
            waitRun:begin
                drpWe <= 0;
                drpEn <=0;
                drpAddr <= 9'b0;  //reset address to ES_CONTROL
                if (DRPRDY)
                    state <= testStart;
                else
                    state <= waitRun;
            end
            testStart: begin
                drpWe <= 0;
                drpEn <= 1;         //Read Status
                drpAddr <= 9'h151;  // ES_CONTROL_STATUS
                state <= waitStart;
            end
            waitStart: begin
                drpEn <= 0;
                drpWe <=0;
                if (DRPRDY) begin
                    if (DRPDO == 6) //running
                        state <= testComplete;
                    else
                        state <= testStart;
                end
                else
                    state <=waitStart;  
            end
            testComplete: begin
                drpEn <= 1;         //Read Status
                drpWe <= 0;
                drpAddr <= 9'h151;  // ES_CONTROL_STATUS
                state <= waitComplete;
            end
            waitComplete: begin
                drpEn <=0;
                if (DRPRDY) begin
                    if ( DRPDO[3:1] == 2 || DRPDO[3:1] == 0)
                        state <= rstCmd;
                    else 
                        state <= testComplete;
                end
                else 
                    state <= waitComplete;
            end
            rstCmd: begin
                drpAddr <= 9'h03D;
                drpEn <= 0;
                drpDi <= 16'hE300;
                drpWe <= 1;
                state <= waitRstCmd;
            end
            waitRstCmd: begin
                drpAddr <= 9'b0;
                drpWe <= 1'b0;
                drpEn <= 0;
                if (DRPRDY)	   
                    state <= getSamples;
                else 
                    state <=waitRstCmd;	 
            end
            getSamples: begin
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520) + 2;
                drpAddr <= 9'h150;
                drpEn <= 1;
                drpWe <= 0;
                state <= storeSamples;
            end
            storeSamples: begin
                drpEn <= 0;
                wea <= 1'b1;
                if (DRPRDY) begin
                    state <= getErrors;
                    samples <= DRPDO;
                    dina <= DRPDO;
                end
                else 
                    state <= storeSamples;
            end
            getErrors: begin
                wea <= 1'b0;
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520) + 3;
                drpAddr <= 9'h14F;
                drpEn <= 1;
                state <= storeErrors;
            end
            storeErrors: begin
                drpEn <= 0;
                wea <= 1'b1;
                if (DRPRDY) begin
                    state <= checkGearshift;
                    errors <= DRPDO;
                    dina <= DRPDO;
                end
                else 
                    state <= storeErrors;
            end
            checkGearshift: begin
                wea <= 1'b0;
                if (errors < (10*minErrorCount) || errors > (1000*minErrorCount)) begin
                    // Check if prescale less than max and if too few errors                    
                    if (prescale <= Max_Prescale && errors <= 10*minErrorCount) begin
                        // Increment prescale for next scan
                        if (nextPrescale + stepPrescale >= Max_Prescale)
                            nextPrescale <= Max_Prescale;
                        else
                            nextPrescale <= prescale + stepPrescale;
                            
                        // If prescale at maximum, move on to next scan
                        if (nextPrescale == Max_Prescale) begin
                            nextScan <= 1;
                            state <= writeNewPrescale;
                        end
                        // Too few errors, write new prescale and restart
                        if (errors <= minErrorCount)
                            state <= writeNewPrescale;
                    end
                    else if (prescale > 0 && errors > 10*minErrorCount) begin
                            // too many errors, decrease prescale
                            if (errors > (1000* minErrorCount) && nextPrescale - (2*stepPrescale) >=0)
                                nextPrescale <= prescale - 2*stepPrescale;
                            else if (nextPrescale - stepPrescale <= 0)
                                nextPrescale <= 0;
                            else
                                nextPrescale <= prescale - stepPrescale;
                            nextScan <= 1;
                            state <= writeNewPrescale;
                    end     
                    else begin
                        // Move on to next scan
                        nextPrescale <= prescale;
                        nextScan <= 1;
                        state <= writeNewPrescale;
                    end
                // Less than 10*minErrorCount but not less than minErrorCount, move onto next scan
                nextScan <= 1;
                state <= writeNewPrescale;
                end
                else begin
                    if (pixelCount > 0) begin
                        state <= writeVert;
                    end
                    else if (hsteps == 0) begin
                        state <= updateHorizontal;
                    end
                    else if (hsteps < 65) begin
                        pixelCount <= pixelCount + 1;
                        state <= updateHorizontal;
                    end
                    else begin
                        pixelCount <= 0;
                        UTsign <= !UTsign;
                        if (UTsign == 1) begin
                                rowNum <= rowNum + 1;
                        end
                        state <= updateHorizontal;
                    end
                end
            end
            writeVert: begin
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520);
                if (vsteps-1 < 255 ) begin // 63 stepsize 4
                    if (vsteps-1 > 126) begin // 30 stepsize 4
                        dina <= {prescale,2'b00,UTsign,1'b1,vertValue};
                    end
                    else begin
                        dina <= {prescale,2'b00,UTsign,1'b0,vertValue};
                    end
                    wea <= 1'b1;
                    state <= waitBRAM;
                end
            end
            waitBRAM: begin
                wea <= 1'b0;
                if (hsteps < 65) begin
                    pixelCount <= pixelCount + 1;
                    state <= updateHorizontal;
                end
                else begin
                    pixelCount <= 0;
                    UTsign <= !UTsign;
                    if (UTsign == 1) begin
                        rowNum <= rowNum + 1;
                    end
                    state <= updateHorizontal;
                end
            end
            writeNewPrescale: begin
                addra <= (pixelCount * 8) + (UTsign * 4) + ((rowNum) * 520);
                prescale <= nextPrescale;
                if (vsteps-1 < 255 ) begin // 63 for stepsize 4
                    drpEn <=0;
                    if (vsteps-1 > 126) begin //30 for step 4
                        dina <= {nextPrescale,2'b00,UTsign,1'b1,vertValue};
                        drpDi <= {nextPrescale,2'b00,UTsign,1'b1,vertValue};
                    end
                    else begin
                        dina <= {nextPrescale,2'b00,UTsign,1'b0,vertValue};
                        drpDi <= {nextPrescale,2'b00,UTsign,1'b0,vertValue};
                    end
                    drpAddr <= 9'h03B;
                    drpWe <= 1;
                    wea <= 1'b1;
                    state <= waitNewPrescale;
                end
                else begin
                    ScanCompleted <= 1;
                    state <= waitGoCmd;
                end
            end
            waitNewPrescale: begin
                drpWe <= 0;
                drpEn <=0;
                wea <= 1'b0;
                if (DRPRDY) begin
                    if (nextScan) begin
                        nextScan <= 0;
                        if (hsteps == 0) begin
                            state <= updateHorizontal;
                        end
                        else if (hsteps < 65) begin
                            pixelCount <= pixelCount + 1;
                            state <= updateHorizontal;
                        end
                        else begin
                            pixelCount <= 0;
                            UTsign <= !UTsign;
                            if (UTsign == 1) begin
                                rowNum <= rowNum + 1;
                            end
                            state <= updateHorizontal;
                        end
                    end
                    else
                        state <= run;
                end
                else
                    state <= waitNewPrescale;
            end
                
            default:
                state <= waitGoCmd;  // Wait for start command
        endcase
        RunScan_old <= RunScan;
        
        // BRAM readout
        // When data eye req is triggered
        // set a flag to process data
        // flag stays high until GetData_cmplt
        if (GetData_eye_req && !GetData_eye_req_old) begin
            beginReadout <= 1;
            GetData_Buffered <= 0;
            waitNext <= 0;
            index <= 0;
        end
        else if (GetData_eye_nxt && !GetData_eye_nxt_old) begin
            GetData_Buffered <= 0;
            waitNext <= 0;
            index <= index + 1;
        end
        GetData_eye_req_old <= GetData_eye_req;
        GetData_eye_nxt_old <= GetData_eye_nxt;
        
        if (beginReadout) begin
            if (DataCntr < 31 && !waitNext) begin //changed datacntr from 31 to 32
                if (bramRead) begin
                    VertData[(DataCntr * 32) +: 32] <= {douta[79:64], douta[15:0]};
                    HorzData[(DataCntr * 32) +: 32] <= {douta[95:80], douta[31:16]};
                    SampleData[(DataCntr * 32) +: 32] <= {douta[111:96], douta[47:32]};
                    ErrorData[(DataCntr * 32) +: 32] <= {douta[127:112], douta[63:48]};
                    DataCntr <= DataCntr + 1;
                    bramRead <= 0;
                end
                else if (bramRdy) begin
                    bramRead <= 1;
                    bramRdy <= 0;
                end
                else begin
                    addra <= (DataCntr * 8) + (248 * index);
                    bramRdy <= 1;
                end
            end
            else if (DataCntr > 30) begin
                if (VertData == 0) begin //16'h0000000000000000 //32'h00000000000000000000000000000000
                    GetData_cmplt <= 1;
                    index <= 0;
                    beginReadout <= 0;
                end
            GetData_Buffered <= 1;
            waitNext <= 1;
            DataCntr <= 0;
            end
            else begin
                DataCntr <= 0;
                GetData_cmplt <= 0;
            end
        end
    end

    always @(posedge CLK ) begin                   // Routine to run the drp using eyeScan inputs
        if (drpDone) begin
            DRPEN <= 1'b0;
            DRPADDR <= 9'b0;
            DRPDI <= 16'b0;
            DRPWE <= 1'b0;
        end
        if (!drpWe && !drpEn) begin
            drpDone <=1'b0;
            DRPEN <= 1'b0;
            DRPADDR <= 9'b0;
            DRPDI <= 16'b0;
            DRPWE <= 1'b0;
        end 
        if (drpWe && !drpDone) begin
            DRPWE <= 1'b1;
            DRPADDR <= drpAddr;
            DRPDI <= drpDi;
            DRPEN <= 1'b1;
            drpDone <= 1'b1;
        end
        if (drpEn && !drpDone) begin
            DRPEN <=1'b1;
            DRPWE <=1'b0;
            DRPADDR <= drpAddr;
            DRPDI <= drpDi;
            drpDone <= 1'b1; 
        end 
    end
endmodule