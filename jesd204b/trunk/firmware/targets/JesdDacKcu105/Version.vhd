-------------------------------------------------------------------------------
-- Title      : Version Constant File
-------------------------------------------------------------------------------
-- File       : Version.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-06-04
-- Last update: 2015-06-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

package Version is

constant FPGA_VERSION_C : std_logic_vector(31 downto 0) := x"00000002"; -- MAKE_VERSION

constant BUILD_STAMP_C : string := "JesdDacKcu105: Vivado v2015.1 (x86_64) Built Fri Jun 12 11:30:30 PDT 2015 by ulegat";

end Version;
 
-------------------------------------------------------------------------------
-- Revision History:
-------------------------------------------------------------------------------
-- 06/05/2015 - 00000000      - Without pgp
-- 06/12/2015 - 00000001      - First complete system