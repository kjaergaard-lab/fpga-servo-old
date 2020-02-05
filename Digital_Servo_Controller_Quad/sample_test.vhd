library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 
use work.Constants.all;
use work.Procedures.all;

entity sample_test is
end sample_test;

architecture Behavioral of sample_test is

constant clk_period : time := 20 ns;

signal clk					:	std_logic	:=	'0';
signal trigIn, reset, genEnabled				:	std_logic	:=	'0';

signal state				:	integer range 0 to 3	:=	0;
signal updateCount		:	integer	:=	0;
signal updateTrig			:	std_logic	:=	'0';
signal sampleCount		:	integer	:=	0;

signal rampSampleOut		:	integer	:=	0;
signal rampSampleCode	:	std_logic_vector(7 downto 0)	:=	X"00";
signal rampIdx				:	integer range 0 to MAX_NUM_RAMPS-1 :=	0;


signal memState			:	integer range 0 to 15	:=	0;
signal memSampleOut		:	integer	:=	0;
signal memSampleCode		:	std_logic_vector(7 downto 0)	:=	X"00";
signal memDelay			:	integer	:=	0;
signal memDelayCount		:	integer	:=	0;
signal memDelayEnable	:	std_logic	:=	'0';

signal loopReg1, loopReg2	:	std_logic_vector(31 downto 0)	:=	(others => '0');

signal sampleOut	:	integer	:=	0;
signal sampleCode	:	std_logic_vector(7 downto 0)	:=	(others => '0');

signal sampleTrig, memReadTrig	:	std_logic	:=	'0';
signal sampleSource	:	std_logic	:=	'1';
signal updateTime	:	integer	:=	10;
signal numSamples	:	integer	:=	9;



constant MEM_DATA	:	int_array(0 to 9)	:=	(	0	=>	0,
															1	=>	0,
															2	=>	2,
															3	=>	3,
															4	=>	1,
															5	=>	1,
															6	=>	1,
															7	=>	1,
															8	=>	1,
															9	=>	1);
															
constant MEM_CODE	:	int_array(0 to 9)	:=	(3 => 128, others => 0);

begin

-- Clock process definitions
clk_process :process
begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
end process;

Update: process(clk,trigIn) is
begin
	if rising_edge(clk) then
		SM: case state is
			--Idle state
			when 0 =>
				sampleCount <= 0;
				sampleTrig <= '0';
				if reset = '1' then
					genEnabled <= '0';
				elsif trigIn = '1' then
					state <= state + 1;
					updateCount <= 1;
					updateTrig <= '0';
					genEnabled <= '1';
				else
					updateCount <= 0;
					updateTrig <= '0';
					genEnabled <= '0';
					memDelayCount <= 0;
				end if;
				
			--Shift data state
			when 1 =>
				state <= state + 1;
				sampleTrig <= '1';
				
				if sampleSource = '0' then
					sampleOut <= rampSampleOut;
					sampleCode <= rampSampleCode;
					sampleCount <= sampleCount + 1;
				elsif memSampleCode(7) = '0' and memDelayEnable = '0' then
					sampleOut <= memSampleOut;
					sampleCode <= memSampleCode;
					memDelayEnable <= '0';
					sampleCount <= sampleCount + 1;
				elsif memSampleCode(7) = '1' then
					memDelay <= memSampleOut;
					sampleCount <= sampleCount + 1;
				end if;
				
			--Wait for updateTime
			when 2 =>
				sampleTrig <= '0';
				if updateCount = 1 then
					updateCount <= updateCount + 1;
					if memDelayEnable = '0' then
						updateTrig <= '1';
						if memSampleCode(7) = '1' then
							memDelayEnable <= '1';
						end if;
					end if;
					
				elsif updateCount < (updateTime - 1) then
					updateCount <= updateCount + 1;
					updateTrig <= '0';
				else
					updateCount <= 1;
					if sampleCount < numSamples then
						state <= 1;
					else
						state <= 0;
					end if;
					
					if memDelayEnable = '1' and memDelayCount < (memDelay - 2) then
						memDelayCount <= memDelayCount + 1;
					else
						memDelayEnable <= '0';
						memDelayCount <= 0;
					end if;
				end if;
				
			when others => null;
		end case;	--end case SM
	end if;	--end rising_edge(clk)
end process;

--
-- This process issues read triggers to the correct memory address and fetches new samples from memory
--
MemoryRamp: process(clk) is
begin
	if rising_edge(clk) then
		MemoryStateMachine: case memState is
			--
			-- Idle state
			--
			when 0 =>
				if (updateTrig = '1' and sampleSource = '1') or reset = '1' then
					--
					-- Read new sample/control signal
					--
					memReadTrig <= '1';
					memState <= memState + 1;
--					memAddr <= MEM_ADDR_PAD_VALUE & ID & SAMPLE_LOCATION & to_unsigned(sampleCount,MEM_ADDR_USER_WIDTH);
				else
					memReadTrig <= '0';
				end if;
				
			--
			-- Reset read trigger
			--
			when 1 =>
				memReadTrig <= '0';
				memState <= memState + 1;
			
			--
			-- Assign data to sample out and sample code
			-- If variable loops are enabled, then need to read out loop registers
			--
			when 2 =>
				memSampleOut <= MEM_DATA(sampleCount);
				memSampleCode <= std_logic_vector(to_unsigned(MEM_CODE(sampleCount),8));
				memState <= 0;

			when others => null;
		end case;
	end if;
end process;


-- Stimulus process
stim_proc: process
begin		
	-- hold reset state for 100 ns.
	reset <= '1';
	wait for 100 ns;	
	trigIn <= '0';
	reset <= '0';
	wait for clk_period*10;
	wait until clk'event and clk = '1';
	trigIn <= '1';
	wait until clk'event and clk = '1';
	trigIn <= '0';

	-- insert stimulus here 

	wait;
end process;


end Behavioral;

