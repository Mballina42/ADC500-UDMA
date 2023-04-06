----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/22/2017 07:24:58 PM
-- Design Name: 
-- Module Name: Decimate_N - Behavioral
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

entity Ndecimator is
    Generic(
        Din_width  : integer  := 8;
        Dout_width : integer  := 16
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
end Ndecimator;

architecture Behavioral of Ndecimator is

constant zeroes : std_logic_vector (Dout_width - Din_width -1 downto 0):=(others=>'0');

signal sum : unsigned(Dout_width -1 downto 0);
signal count : unsigned(Dout_width -1 downto 0);
signal Dout_sig : unsigned(Dout_width -1 downto 0);
signal dv : std_logic;

begin

    DOUT<=std_logic_vector(Dout_sig);
    DOValid<=dv;
    CNT<=std_logic_vector(count);

    process(CLK, resetn)
    begin
        if resetn = '0' then 
            sum<=(others=>'0');
            count<=(others=>'0');
            Dout_sig<=(others=>'0');
        elsif rising_edge(CLK) then
            if DIvalid='1' then
                if unsigned(N) = 0 then
                    Dout_sig<=unsigned(zeroes & Din);
                    dv<='1';
                    sum<=(others=>'0');
                elsif count >= (unsigned(N) - 1) then 
                    Dout_sig<=sum;
                    sum<=unsigned(zeroes & DIN);
                    count<=(others=>'0');
                    dv<='1';
                else
                    Dout_sig<=Dout_sig;
                    sum<=sum+unsigned(DIN);
                    count<=count+1;
                    dv<='0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;