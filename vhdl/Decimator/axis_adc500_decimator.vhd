----------------------------------------------------------------------------------
-- Company: ICTP
-- Engineer: L. Garcia
-- 
-- Create Date: 05/22/2017 07:24:58 PM
-- Design Name: 
-- Module Name: adc_decimator.vhd - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axis_adc500_decimator is
    Generic(Dout_width : integer  := 32;
            max_burst : integer :=255);
    Port ( 
       axis_aclk     : in STD_LOGIC;
       axis_resetn  : in STD_LOGIC;

       N        : in STD_LOGIC_VECTOR ((Dout_width-9)-1 downto 0); --Nmax=2**(2*(Dout_width - Din_width))
       
       --AXIS signals
       m_axis_tdata  : out STD_LOGIC_VECTOR(64-1 downto 0); --Data + time width bits
       m_axis_tkeep  : out STD_LOGIC_VECTOR(8 -1 downto 0); --Data + time width bytes to keep time
       m_axis_tvalid : out STD_LOGIC;
       m_axis_tlast  : out STD_LOGIC;
       m_axis_tready : in STD_LOGIC;

       s_axis_tdata  : in STD_LOGIC_VECTOR(32 - 1 downto 0);
       s_axis_tkeep  : in STD_LOGIC_VECTOR(4 -1 downto 0);
       s_axis_tvalid : in STD_LOGIC;
    --    s_axis_tlast  : in STD_LOGIC;
       s_axis_tready : out STD_LOGIC
       );
end axis_adc500_decimator;

architecture Behavioral of axis_adc500_decimator is

    component adc500_decimator is
        Generic(
            Twidth     : integer  := 32;
            Dout_width : integer  := 32
        );
        Port ( 
           CLK     : in STD_LOGIC;
           resetn  : in STD_LOGIC;
    
           N        : in STD_LOGIC_VECTOR ((Dout_width-9)-1 downto 0); --Nmax=2**(2*(Dout_width - Din_width))
           
           TimeIn   : in STD_LOGIC_VECTOR (Twidth - 1 downto 0);
           TimeOut  : out STD_LOGIC_VECTOR (Twidth - 1 downto 0);
    
           Din      : in STD_LOGIC_VECTOR (16 - 1 downto 0);
           DIvalid  : in STD_LOGIC;
    
           Dout     : out STD_LOGIC_VECTOR (Dout_width - 1 downto 0);
           DOValid  : out STD_LOGIC
           );
    end component;

    signal data :  STD_LOGIC_VECTOR (Dout_width - 1 downto 0);
    signal tsig :  STD_LOGIC_VECTOR (16 - 1 downto 0);


    signal TimeIn   : STD_LOGIC_VECTOR (16 - 1 downto 0); 
    signal Din      : STD_LOGIC_VECTOR (16 - 1 downto 0);

    signal d0_mask : std_logic_vector(7 downto 0); --masks for tkeep
    signal d1_mask : std_logic_vector(7 downto 0);
    signal counter : unsigned(31 downto 0);
    signal tvalid : std_logic;

begin

    d0_mask<=(others=>s_axis_tkeep(0));
    d1_mask<=(others=>s_axis_tkeep(1));

    TimeIn<=s_axis_tdata(32-1 downto 16) when s_axis_tvalid='1' else (others=>'0');
    Din<=s_axis_tdata(16-1 downto 0) and (d1_mask & d0_mask) when s_axis_tvalid='1' else (others=>'0');
    s_axis_tready<='1';
    
    --m_axis_tdata<=x"0000"&tsig&data when m_axis_tready='1' else (others=>'0');
    m_axis_tdata<=x"00000000"&x"0000"&data(15 downto 0) when m_axis_tready='1' else (others=>'0');
    m_axis_tkeep(8-1 downto 4)<="00" & s_axis_tkeep(3 downto 2);
    m_axis_tkeep(3 downto 0)<=(others=>'1');
    m_axis_tlast<='1' when counter=(max_burst-1) and tvalid ='1' else '0';
    m_axis_tvalid<=tvalid;

    dec: adc500_decimator
        Generic map(
            Twidth     =>16,
            Dout_width =>Dout_width
        )
        Port map( 
            CLK      =>axis_aclk,
            resetn   =>axis_resetn,
            N        =>N,
            TimeIn   =>TimeIn,
            TimeOut  =>tsig,
            Din      =>Din,
            DIvalid  =>s_axis_tvalid,
            Dout     =>data,
            DOValid  =>tvalid
           );

           process(axis_aclk, axis_resetn)
           begin
               if axis_resetn ='0' then
                   counter<=(others=>'0');
                elsif rising_edge(axis_aclk) then
                    if m_axis_tready ='0' then
                        counter<=(others=>'0');
                    elsif counter >=max_burst or m_axis_tready='0' then
                        counter<=(others=>'0');
                    elsif tvalid ='1' then
                        counter<=counter+1;
                    end if;
               end if;
           end process;
   

       
end Behavioral;