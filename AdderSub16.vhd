library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SumRest16Bits is Port (
		A : in std_logic_vector(15 downto 0);
		B : in std_logic_vector(15 downto 0);
		Cin : in std_logic;
		Op : in std_logic;
		Res : out std_logic_vector(15 downto 0);
		Cout : out std_logic
	);
end SumRest16Bits;

architecture Behavioral of SumRest16Bits is

signal intermediate_carry : std_logic_vector(16 downto 0);
signal B_mod : std_logic_vector(15 downto 0);

begin

Process(A, B, Op)
begin
    if Op = '1' then  
        B_mod <= not B;  -- Complemento de B para la resta
        intermediate_carry(0) <= '1';  -- Iniciar con un acarreo de '1' para sumar al complemento de B
    else 
        B_mod <= B;
        intermediate_carry(0) <= Cin;  -- Usar el acarreo de entrada para la suma
    end if;
end process;

Gen_SumRest: for i in 0 to 15 generate
begin
    Res(i) <= A(i) xor B_mod(i) xor intermediate_carry(i);
    intermediate_carry(i+1) <= (A(i) and B_mod(i)) or (A(i) and intermediate_carry(i)) or (B_mod(i) and intermediate_carry(i));
end generate;

Cout <= intermediate_carry(16) xor Op;

end Behavioral;