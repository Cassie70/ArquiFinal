library ieee;
use ieee.std_logic_1164.all;

entity alu is port(
	clk: in std_logic;
	reset: in std_logic;
	A,B: in std_logic_vector(15 downto 0);
	control: in std_logic_vector(3 downto 0);
	result: out std_logic_vector(15 downto 0);
	C,Z,S,V,end_div: out std_logic
);
end alu;

architecture a_alu of alu is

	component SumRest16Bits is Port (
		A : in std_logic_vector(15 downto 0);
		B : in std_logic_vector(15 downto 0);
		Cin : in std_logic;
		Op : in std_logic;
		Res : out std_logic_vector(15 downto 0);
		Cout : out std_logic
	);
	end component;
	
	component multi8 is port(
        A, B: in std_logic_vector(7 downto 0);
        result: out std_logic_vector(15 downto 0)
    );
	end component;
	
	component divi8 is
		port(
			clk: in std_logic;
			enable: in std_logic;
			reset: in std_logic;
			A, B: in std_logic_vector(7 downto 0);
			result: out std_logic_vector(7 downto 0);
			end_flag: out std_logic
		);
	end component;
	
	constant two : std_logic_vector(15 downto 0):="0000000000000010";
	constant one : std_logic_vector(15 downto 0):="0000000000000001";
	constant zero: std_logic_vector(15 downto 0):="0000000000000000";
	
	signal substract: std_logic;
	signal sum_result: std_logic_vector(15 downto 0);
	signal logic_result: std_logic_vector(15 downto 0);
	signal multi_result: std_logic_vector(15 downto 0);
	signal div_result: std_logic_vector(7 downto 0);
	signal all_results: std_logic_vector(15 downto 0);
	signal A_temp,B_temp: std_logic_vector(15 downto 0);
	signal en_div: std_logic;

begin
	imp_add_sub_12: SumRest16Bits port map(A_temp,B_temp,'0',substract,sum_result,C);
	imp_multi: multi8 port map(A_temp(7 downto 0),B_temp(7 downto 0),multi_result);
	imp_div: divi8 port map(clk,en_div,reset,A_temp(7 downto 0),B_temp(7 downto 0),div_result,end_div);
	
	input_process:process(A,B,control)
	begin
		case control is
			when "0000"=>--A+B  1 BYTE
				A_temp<="00000000"&A(7 downto 0);
				B_temp<="00000000"&B(7 downto 0);
				substract<='0';
				en_div <= '0';
			when "0001"=>--A-B 1 BYTE
				A_temp<="00000000"&A(7 downto 0);
				B_temp<="00000000"&B(7 downto 0);
				substract<='1';
				en_div <= '0';
			when "0010"=>--A+1
				A_temp<=A;
				B_temp<=one;
				substract<='0';
				en_div <= '0';
			when "0011"=>--A-1
				A_temp<=A;
				B_temp<=one;
				substract<='1';
				en_div <= '0';
			when "0100"=>--B+1
				A_temp<=B;
				B_temp<=one;
				substract<='0';
				en_div <= '0';
			when "0101"=>--B-1
				A_temp<=B;
				B_temp<=one;
				substract<='1';
				en_div <= '0';
			when "0110"=>--A+B 16 BITS
				A_temp<=A;
				B_temp<=B;
				substract<='0';
				en_div <= '0';
			when "0111"=>--A-B 16 BITS
				A_temp<=A;
				B_temp<=B;
				substract<='1';
				en_div <= '0';
			when "1000"=>--AND
				logic_result<=A and B;
				en_div <= '0';
			when "1001"=>--OR
				logic_result<=A or B;
				en_div <= '0';
			when "1010"=>--XOR
				logic_result<=A xor B;
				en_div <= '0';
			when "1011"=>--COMP A 1
				A_temp<=not A;
				B_temp<=zero;
				substract<='0';
				en_div <= '0';
			when "1100"=>--COMP A 2
				A_temp<=zero;
				B_temp<=A;
				substract<='1';
				en_div <= '0';
			when "1101"=>--A*B 8 BITS
				A_temp<="00000000"&A(7 downto 0);
				B_temp<="00000000"&B(7 downto 0);
				en_div <= '0';
			when "1110"=>--A/B 8 BITS
				A_temp<="00000000"&A(7 downto 0);
				B_temp<="00000000"&B(7 downto 0);
				en_div <= '1';
			when "1111"=>--A LSL
				A_temp<=A;
				B_temp<=A;
				en_div <= '0';
			when others=>
				A_temp<=zero;
				B_temp<=zero;
				en_div <= '0';
		end case;
	end process input_process;
	
	flag_z :process(all_results)
    begin
        if all_results = zero then
            Z <= '1'; 
        else
            Z <= '0';
        end if;
    end process flag_z;
	
	flag_s: process(all_results)
	begin
		S <= all_results(11);
	end process flag_s;
	
	flag_v: process(all_results)
	begin
		V <= (A(11) and B(11) and not(all_results(11))) or (not(A(11)) and not(B(11)) and all_results(11));
	end process flag_v;
	
	with control select
		all_results<=sum_result   when "0000",
					 sum_result   when "0001",
					 sum_result   when "0010",
					 sum_result   when "0011",
					 sum_result   when "0100",
					 sum_result   when "0101",
					 sum_result   when "0110",
					 sum_result   when "0111",
					 logic_result when "1000",
					 logic_result when "1001",
					 logic_result when "1010",
					 sum_result   when "1011",
					 sum_result   when "1100",
					 multi_result when "1101",
		             "00000000"&div_result   when "1110",
					 sum_result   when "1111",
					 zero         when others;
	result <= all_results;
end a_alu;