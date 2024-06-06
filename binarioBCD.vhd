library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Bin2BCD is
    Port ( 
        clr: in std_logic;
        bin_in : in std_logic_vector(13 downto 0);
        bcd_out: out std_logic_vector(15 downto 0)
    );
end Bin2BCD;

architecture Behavioral of Bin2BCD is
begin
    process(bin_in, clr)
    variable Z: std_logic_vector(29 downto 0);
    begin
        if(clr = '1') then
            bcd_out <= (others => '0');
        else
            Z := "0000000000000000" & bin_in;
            for i in 0 to 13 loop
                if Z(17 downto 14) > "0100" then
                    Z(17 downto 14) := Z(17 downto 14) + "0011";
                end if;

                if Z(21 downto 18) > "0100" then
                    Z(21 downto 18) := Z(21 downto 18) + "0011";
                end if;

                if Z(25 downto 22) > "0100" then
                    Z(25 downto 22) := Z(25 downto 22) + "0011";
                end if;

                if Z(29 downto 26) > "0100" then
                    Z(29 downto 26) := Z(29 downto 26) + "0011";
                end if;
                Z := Z(28 downto 0) & '0';
            end loop;
            bcd_out <= Z(29 downto 14); 
        end if;
    end process;
end Behavioral;