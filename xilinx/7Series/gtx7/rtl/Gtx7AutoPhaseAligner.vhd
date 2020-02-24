--////////////////////////////////////////////////////////////////////////////////
--//   ____  ____ 
--//  /   /\/   / 
--// /___/  \  /    Vendor: Xilinx 
--// \   \   \/     Version : 2.5
--//  \   \         Application : 7 Series FPGAs Transceivers Wizard 
--//  /   /         Filename : gtwizard_v2_5_auto_phase_align.vhd
--// /___/   /\     
--// \   \  /  \ 
--//  \___\/\___\ 
--//
--//
--  Description : The logic below implements the procedure to do automatic phase-alignment 
--                on the 7-series GTX as described in ug476pdf, version 1.3,
--                Chapters "Using the TX Phase Alignment to Bypass the TX Buffer"
--                and "Using the RX Phase Alignment to Bypass the RX Elastic Buffer"
--                Should the logic below differ from what is described in a later version  
--                of the user-guide, you are using an auto-alignment block, which is 
--                out of date and needs to be updated for safe operation.
--                     
--
--
-- Module gtwizard_v2_5_AUTO_PHASE_ALIGN
-- Generated by Xilinx 7 Series FPGAs Transceivers Wizard
-- 
-- 
-- (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES. 


--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library surf;

entity Gtx7AutoPhaseAligner is     
  Generic( 
           GT_TYPE                  : string  := "GTX"
         );     

    Port ( STABLE_CLOCK             : in  STD_LOGIC;              --Stable Clock, either a stable clock from the PCB
                                                                  --or reference-clock present at startup.
           RUN_PHALIGNMENT          : in  STD_LOGIC;              --Signal from the main Reset-FSM to run the auto phase-alignment procedure
           PHASE_ALIGNMENT_DONE     : out STD_LOGIC := '0';       -- Auto phase-alignment performed sucessfully
           PHALIGNDONE              : in  STD_LOGIC;              --\ Phase-alignment signals from and to the
           DLYSRESET                : out STD_LOGIC;              -- |transceiver.
           DLYSRESETDONE            : in  STD_LOGIC;              --/
           RECCLKSTABLE             : in  STD_LOGIC               --/on the RX-side.
           
           );
end Gtx7AutoPhaseAligner;

architecture RTL of Gtx7AutoPhaseAligner is

--  component gtwizard_v2_5_sync_block
--   generic (
--     INITIALISE : bit_vector(1 downto 0) := "00"
--   );
--   port  (
--             clk           : in  std_logic;
--             data_in       : in  std_logic;
--             data_out      : out std_logic
--          );
--   end component;

  type phase_align_auto_fsm is(
    INIT, WAIT_PHRST_DONE, COUNT_PHALIGN_DONE, PHALIGN_DONE
    );
    
  signal phalign_state       : phase_align_auto_fsm := INIT;
  signal phaligndone_prev     : std_logic := '0';
  signal phaligndone_ris_edge : std_logic;

  signal count_phalign_edges   : integer range 0 to 3:= 0;
  signal phaligndone_sync      : std_logic := '0';
  signal dlysresetdone_sync    : std_logic := '0';

   attribute KEEP_HIERARCHY : string;
   attribute KEEP_HIERARCHY of 
      sync_PHALIGNDONE,
      sync_DLYSRESETDONE : label is "TRUE";
   
begin

 sync_PHALIGNDONE : entity surf.Synchronizer
  port map
         (
            clk             =>  STABLE_CLOCK,
            dataIn         =>  PHALIGNDONE,
            dataOut        =>  phaligndone_sync 
         );

  sync_DLYSRESETDONE : entity surf.Synchronizer
  port map
         (
            clk             =>  STABLE_CLOCK,
            dataIn         =>  DLYSRESETDONE,
            dataOut        =>  dlysresetdone_sync 
         );


  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      phaligndone_prev <= phaligndone_sync; 
    end if;
  end process;
  phaligndone_ris_edge <= '1' when (phaligndone_prev = '0') and (phaligndone_sync = '1') else '0';
  
  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      if RUN_PHALIGNMENT = '0' or RECCLKSTABLE = '0' then
        DLYSRESET           <= '0';
        count_phalign_edges   <= 0;
        PHASE_ALIGNMENT_DONE  <= '0';
        phalign_state      <= INIT;
      else
        if phaligndone_ris_edge = '1' then
          if count_phalign_edges < 3 then
            count_phalign_edges <= count_phalign_edges + 1;
          end if;
        end if;
        
        DLYSRESET         <= '0';
                  
        case phalign_state is
          when INIT => 
            PHASE_ALIGNMENT_DONE <= '0';
            if RUN_PHALIGNMENT = '1' and RECCLKSTABLE = '1' then
              --DLYSRESET is toggled to '1'
              DLYSRESET  <= '1';
              phalign_state <= WAIT_PHRST_DONE;
            end if;           
            
          when WAIT_PHRST_DONE =>
            if dlysresetdone_sync = '1' then
              phalign_state <= COUNT_PHALIGN_DONE;
            end if;
            --No timeout-check here as that is done in the main FSM
            
          when COUNT_PHALIGN_DONE =>
            if ((GT_TYPE = "GTX" and count_phalign_edges = 2) or ((GT_TYPE = "GTH" or GT_TYPE = "GTP") and phaligndone_ris_edge = '1')) then
              --For GTX: Only on the second edge of the PHALIGNDONE-signal the 
              --         phase-alignment is completed
              --For GTH, GTP: TXSYNCDONE indicates the completion of Phase Alignment

              phalign_state <= PHALIGN_DONE;
            end if;
          
          when PHALIGN_DONE =>
            PHASE_ALIGNMENT_DONE <= '1';

          when OTHERS =>
            phalign_state      <= INIT;

        end case;        
      end if;      
    end if;    
  end process;

end RTL;

