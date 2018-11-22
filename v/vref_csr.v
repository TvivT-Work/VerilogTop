//=================================================================================
// Filename: vref_csr.v                                                 
// Author  : jianghe                                                            
// Abstract:                                                                       
//---------------------------------------------------------------------------------
// Description:                                                                    
//                                                                                 
//---------------------------------------------------------------------------------
// Modification History:                                                           
//---------------------------------------------------------------------------------
//    Rev           date          Author         description                       
//    0.00         20180822       jianghe           Creat it                 
//=================================================================================
`timescale 1ns/10ps                                                              


module vref_csr(
    input  wire   [31:0]   vref_paddr              ,
    input  wire   [31:0]   vref_pwdata             ,
    input  wire            vref_pwrite             ,
    input  wire   [ 3:0]   vref_pstrb              ,
    input  wire            vref_psel               ,
    input  wire            vref_penable            ,
    input  wire   [ 2:0]   vref_pprot              ,
    input  wire   [ 2:0]   vref_pmaster            ,

    output wire   [31:0]   vref_prdata             ,
    output wire            vref_pready             ,
    output wire            vref_pslverr            ,

    input  wire            bg_flag                ,


    output reg    [ 1:0]   sc_mode                ,
    output reg             ldo_en                 ,
    output reg             vref_en                ,
    output reg    [ 3:0]   bjt_trim               ,
    output reg    [ 7:0]   res_trim               ,
                                                                                  
    input  wire            vref_pclk               ,                         
    input  wire            vref_rst_n                                        
                                                                                  
);                                                                                
                                                                                  
                                                                                  
//==========================================  DECLARE  ==========================================
assign  vref_pready  = 1'b1                                 ;
assign  vref_pslverr = 1'b0                                 ;

//--------------------------------------------------------  
wire    vref_mmu_cs                                         ;
assign  vref_mmu_cs = vref_psel & vref_penable              ;

wire    super_access                                        ;
assign  super_access = vref_pprot[0]                        ;
//--------------------------------------------------------  

wire              cs_vref_ctrl            ;
wire              cs_vref_trim            ;
wire              cs_vref_bg_flag         ;

wire              wr_vref_ctrl            ;
wire              wr_vref_trim            ;

wire              rd_vref_ctrl            ;
wire              rd_vref_trim            ;
wire              rd_vref_bg_flag         ;

wire     [31:0]   data_vref_ctrl          ;
wire     [31:0]   data_vref_trim          ;
wire     [31:0]   data_vref_bg_flag       ;


//==========================================  ASSIGN  ===========================================
assign  cs_vref_ctrl          = ( vref_mmu_cs & {vref_paddr[11:2],2'b0}==`REG_VREF_CTRL      );
assign  cs_vref_trim          = ( vref_mmu_cs & {vref_paddr[11:2],2'b0}==`REG_VREF_TRIM      );
assign  cs_vref_bg_flag       = ( vref_mmu_cs & {vref_paddr[11:2],2'b0}==`REG_VREF_BG_FLAG   );

assign  wr_vref_ctrl          = ( cs_vref_ctrl        &  vref_pwrite );
assign  wr_vref_trim          = ( cs_vref_trim        &  vref_pwrite );

assign  rd_vref_ctrl          = ( cs_vref_ctrl        & ~vref_pwrite );
assign  rd_vref_trim          = ( cs_vref_trim        & ~vref_pwrite );
assign  rd_vref_bg_flag       = ( cs_vref_bg_flag     & ~vref_pwrite );


//============================================  REG  READ  ============================================
assign  data_vref_ctrl        = { 28'h0, sc_mode, ldo_en, vref_en };
assign  data_vref_trim        = { 20'h0, bjt_trim, res_trim };
assign  data_vref_bg_flag     = { 31'h0, bg_flag };


assign  vref_prdata = ( rd_vref_ctrl        ?  data_vref_ctrl       : 32'h0000_0000 ) | 
                      ( rd_vref_trim        ?  data_vref_trim       : 32'h0000_0000 ) | 
                      ( rd_vref_bg_flag     ?  data_vref_bg_flag    : 32'h0000_0000 ) ; 


//============================================  REG WRITE  ============================================
// MCU Write Register: vref_ctrl 
always @(posedge vref_pclk or negedge vref_rst_n)  begin 
    if(~vref_rst_n)  begin 
        sc_mode              <= #1 2'b00                                             ;
        ldo_en               <= #1 1'b0                                              ;
        vref_en              <= #1 1'b0                                              ;
    end 
    else begin 
        sc_mode[1:0]         <= #1 ( wr_vref_ctrl      && vref_pstrb[0] ) ? vref_pwdata[3:2]         : sc_mode[1:0]          ;
        ldo_en               <= #1 ( wr_vref_ctrl      && vref_pstrb[0] ) ? vref_pwdata[1]           : ldo_en                ;
        vref_en              <= #1 ( wr_vref_ctrl      && vref_pstrb[0] ) ? vref_pwdata[0]           : vref_en               ;
    end 
end 


// MCU Write Register: vref_trim 
always @(posedge vref_pclk or negedge vref_rst_n)  begin 
    if(~vref_rst_n)  begin 
        bjt_trim             <= #1 4'b1000                                           ;
        res_trim             <= #1 8'b10101011                                       ;
    end 
    else begin 
        bjt_trim[3:0]        <= #1 ( wr_vref_trim      && vref_pstrb[1] ) ? vref_pwdata[11:8]        : bjt_trim[3:0]         ;
        res_trim[7:0]        <= #1 ( wr_vref_trim      && vref_pstrb[0] ) ? vref_pwdata[7:0]         : res_trim[7:0]         ;
    end 
end 


// MCU Write Register: vref_bg_flag 


//=====================================================================================================



endmodule 
