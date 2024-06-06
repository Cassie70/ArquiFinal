library ieee;
use ieee.std_logic_1164.all;

entity multi8 is port(
        A, B: in std_logic_vector(7 downto 0);
        result: out std_logic_vector(15 downto 0)
    );
end multi8;

architecture a_multi8 of multi8 is
	component SumRest16Bits is Port (
		A : in std_logic_vector(15 downto 0);
		B : in std_logic_vector(15 downto 0);
		Cin : in std_logic;
		Op : in std_logic;
		Res : out std_logic_vector(15 downto 0);
		Cout : out std_logic
	);
	end component;

    signal v1, v2, v3, v4, v5, v6, v7, v8: std_logic_vector(15 downto 0);
    signal v12, v34, v56, v78, v12_34, v56_78, v1234_5678: std_logic_vector(15 downto 0);
begin
    v1 <= "00000000" & (A(7) and B(0)) & (A(6) and B(0)) & (A(5) and B(0)) & (A(4) and B(0)) & (A(3) and B(0)) & (A(2) and B(0)) & (A(1) and B(0)) & (A(0) and B(0));
    v2 <= "0000000" & (A(7) and B(1)) & (A(6) and B(1)) & (A(5) and B(1)) & (A(4) and B(1)) & (A(3) and B(1)) & (A(2) and B(1)) & (A(1) and B(1)) & (A(0) and B(1)) & "0";
    v3 <= "000000" & (A(7) and B(2)) & (A(6) and B(2)) & (A(5) and B(2)) & (A(4) and B(2)) & (A(3) and B(2)) & (A(2) and B(2)) & (A(1) and B(2)) & (A(0) and B(2)) & "00";
    v4 <= "00000" & (A(7) and B(3)) & (A(6) and B(3)) & (A(5) and B(3)) & (A(4) and B(3)) & (A(3) and B(3)) & (A(2) and B(3)) & (A(1) and B(3)) & (A(0) and B(3)) & "000";
    v5 <= "0000" & (A(7) and B(4)) & (A(6) and B(4)) & (A(5) and B(4)) & (A(4) and B(4)) & (A(3) and B(4)) & (A(2) and B(4)) & (A(1) and B(4)) & (A(0) and B(4)) & "0000";
    v6 <= "000" & (A(7) and B(5)) & (A(6) and B(5)) & (A(5) and B(5)) & (A(4) and B(5)) & (A(3) and B(5)) & (A(2) and B(5)) & (A(1) and B(5)) & (A(0) and B(5)) & "00000";
	v7 <= "00" & (A(7) and B(6)) & (A(6) and B(6)) & (A(5) and B(6)) & (A(4) and B(6)) & (A(3) and B(6)) & (A(2) and B(6)) & (A(1) and B(6)) & (A(0) and B(6)) & "000000";
	v8 <= "0" & (A(7) and B(7)) & (A(6) and B(7)) & (A(5) and B(7)) & (A(4) and B(7)) & (A(3) and B(7)) & (A(2) and B(7)) & (A(1) and B(7)) & (A(0) and B(7)) & "0000000";
    
    adder12:   SumRest16Bits port map(v1, v2, '0', '0' , v12, open);
	adder34:   SumRest16Bits port map(v3, v4, '0', '0' , v34, open);
	adder56:   SumRest16Bits port map(v5, v6, '0', '0' , v56, open);
	adder78:   SumRest16Bits port map(v7, v8, '0', '0' , v78, open);
	adder1234: SumRest16Bits port map(v12, v34, '0', '0' , v12_34, open);
	adder5678: SumRest16Bits port map(v56, v78, '0', '0' , v56_78, open);
	
	adderFN:   SumRest16Bits port map(v12_34, v56_78, '0', '0' , v1234_5678, open);
	
    result <= v1234_5678;
end a_multi8;