library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity divi8 is
    port(
        clk: in std_logic;
		enable: in std_logic;
		reset: in std_logic;
        A, B: in std_logic_vector(7 downto 0);
        result: out std_logic_vector(7 downto 0);
		end_flag: out std_logic
    );
end entity;

architecture a_divi8 of divi8 is
    component SumRest16Bits is
        Port (
            A : in std_logic_vector(15 downto 0);
            B : in std_logic_vector(15 downto 0);
            Cin : in std_logic;
            Op : in std_logic;
            Res : out std_logic_vector(15 downto 0);
            Cout : out std_logic
        );
    end component;

	signal A_temp,B_temp: std_logic_vector(15 downto 0);
	signal Res: std_logic_vector(15 downto 0);
	signal count,count_temp: std_logic_vector(15 downto 0);
	constant one: std_logic_vector(15 downto 0):= "0000000000000001";
	type state_type is (t0,t1,t2,finish); 
	signal state: state_type;
begin
	restador: SumRest16Bits port map(A_temp,B_temp,'0','1',Res,open);
	contador: SumRest16Bits port map(count_temp,one,'0','0',count,open);
process(clk)
	begin
		if enable = '0' then
			result<=(others=>'Z');
			state <= t0;
		elsif reset = '1' then
			result <= (others=>'0');
			state <= t0;
			end_flag<='0';
		elsif rising_edge(clk) then
			case state is 
				when t0 =>
					end_flag<='0';
					A_temp <= "00000000"&A;
					B_temp <= "00000000"&B;
					count_temp<= (others=>'0');
					result<=(others=>'0');
					state <= t1;
				when t1 =>
					if(Res(7 downto 0) = "00000000" or Res(15) = '1') then
						state <= t2;
					else
						A_temp <= Res;
						count_temp<=count;
						state <= t1;
						result<=count(7 downto 0);
					end if;
				when t2 =>
					if(Res(15) = '0') then
						result<=count(7 downto 0);
					else
						result<=count_temp(7 downto 0);
					end if;
					end_flag<='1';
					state <= finish;
				when finish =>
					state <= finish;
					end_flag <= '0';
			end case;
		end if;
end process;
end architecture;
