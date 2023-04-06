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

entity adc500_decimator is
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
end adc500_decimator;

architecture Behavioral of adc500_decimator is

    component Ndecimator is
        Generic(
            Din_width  : integer  := 9;
            Dout_width : integer  := 32
            );
        Port ( 
           CLK     : in STD_LOGIC;
           resetn  : in STD_LOGIC;
           CNT     : out STD_LOGIC_VECTOR(Dout_width -1 downto 0);
    
           N        : in STD_LOGIC_VECTOR ((Dout_width-Din_width)-1 downto 0); --Nmax=2**(2*(Dout_width - Din_width))
           
           Din      : in STD_LOGIC_VECTOR (Din_width - 1 downto 0);
           DIvalid  : in STD_LOGIC;
           
           Dout     : out STD_LOGIC_VECTOR (Dout_width - 1 downto 0);
           DOValid  : out STD_LOGIC
           );
    end component;

    signal d0, d1, dmask : std_logic_vector(7 downto 0);
    signal sum : unsigned (9 - 1 downto 0);
    signal dout_sig : std_logic_vector(Dout_width -1 downto 0);
    signal TMR : std_logic_vector(Twidth -1 downto 0);
    signal dvalid, oddev : std_logic;
    signal count : STD_LOGIC_VECTOR(Dout_width -1 downto 0);
    
    signal nd2 : std_logic_vector((Dout_width-9)-1 downto 0);

    constant zeroes : std_logic_vector(Dout_width-8-1 downto 0):=(others=>'0');
    constant ozeroes : std_logic_vector(Dout_width-16-1 downto 0):=(others=>'0');

begin
    d0<=Din(7 downto 0);
    d1<=Din(15 downto 8);
    
    sum<=unsigned('0' & d0) + unsigned('0' & (dmask and d1)) when count= (nd2 -1) else
         unsigned('0' & d0) + unsigned('0' & d1);
    
    oddev<=N(0); --odd or even bit
    nd2<=('0' & N((Dout_width-9)-1 downto 1))+oddev; --Divided by 2 and add 1 if it is even
    
    dmask<=(others=>not(oddev)); --set mask to substract MSB in case is odd
    
    DOUT<=ozeroes & DIN when (unsigned(N)<=1) else 
          std_logic_vector(unsigned(dout_sig));
    DOValid<=dvalid;

    dec: Ndecimator
        Generic map(
            Din_width  => 9,
            Dout_width => Dout_width
            )
        Port map( 
           CLK     => CLK,
           resetn  => resetn,
           CNT     => count,
           N       => nd2,
           Din     => std_logic_vector(sum),
           DIvalid => DIvalid,
           Dout    => Dout_sig,
           DOValid => dvalid
           );
        
        
       TMR<=TimeIn when count=0 else TMR;
       TimeOut<=TMR;
       
end Behavioral;