library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.VIDEO_TIMING_pkg.all;

entity TEXTSCR2 is
generic(
	CURLINE	:integer	:=4;
	CBLINKINT :integer	:=20;
	BLINKINT :integer	:=40
);
port(
	TRAMADR	:out std_logic_vector(11 downto 0);
	TRAMDAT	:in std_logic_vector(7 downto 0);
	
	FRAMADR	:out std_logic_vector(11 downto 0);
	FRAMDAT0:in std_logic_vector( 7 downto 0);
	FRAMDAT1:in std_logic_vector( 7 downto 0);
	
	BITOUT	:out std_logic;
	FGCOLOR	:out std_logic_vector(2 downto 0);
	BGCOLOR	:out std_logic_vector(2 downto 0);
	BLINK	:out std_logic;
	
	CURL	:in std_logic_vector(4 downto 0);
	CURC	:in std_logic_vector(6 downto 0);
	CURE	:in std_logic;
	CURM	:in std_logic;
	CBLINK	:in std_logic;
	
	HMODE	:in std_logic;
	VMODE	:in std_logic;
	
	UCOUNT	:in integer range 0 to DOTPU-1;
	HUCOUNT	:in integer range 0 to (HWIDTH/DOTPU)-1;
	VCOUNT	:in integer range 0 to VWIDTH-1;
	HCOMP	:in std_logic;
	VCOMP	:in std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end TEXTSCR2;

architecture MAIN of TEXTSCR2 is
signal	CURDOT	:std_logic_vector(7 downto 0);
signal	NXTDOT0	:std_logic_vector(7 downto 0);
signal	NXTDOT1	:std_logic_vector(7 downto 0);
signal	NXTFGCLR :std_logic_vector(2 downto 0);
signal	NXTBGCLR :std_logic_vector(2 downto 0);
signal	NXTFS	:std_logic;
signal	NXTBL	:std_logic;
signal	CHAR	:std_logic_vector(7 downto 0);
signal	TRAMADRb	:std_logic_vector(11 downto 0);
signal	DHCOMP	:std_logic;
signal	DVCOMP	:std_logic;
signal	C_LOW	:integer range 0 to 31;
signal	C_LIN	:integer range 0 to 19;
signal	C_COL	:integer range 0 to 127;
signal	iCURL	:integer range 0 to 31;
signal	iCURC	:integer range 0 to 127;
signal	CURV	:std_logic;
signal	CURF	:std_logic;
signal	CICOUNT	:integer range 0 to CBLINKINT-1;
signal	BLKF	:std_logic;
signal	BICOUNT	:integer range 0 to BLINKINT-1;
signal	CHRLINES	:integer range 0 to 20;
signal	VMODEC	:std_logic;
signal	HMODEC	:std_logic;

component delayer is
generic(
	counts	:integer	:=5
);
port(
	a		:in std_logic;
	q		:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

begin

	iCURL<=conv_integer(CURL);
	iCURC<=conv_integer(CURC);

	Hdelay	:delayer generic map(1) port map(HCOMP,DHCOMP,clk,rstn);
	Vdelay	:delayer generic map(2) port map(VCOMP,DVCOMP,clk,rstn);

	C_LIN<=0 when VCOUNT<VIV else (VCOUNT-VIV)mod CHRLINES;
	C_COL<=0 when HUCOUNT<HIV else HUCOUNT-HIV;

	process(clk,rstn)begin
		if(rstn='0')then
			CURF<='1';
			CICOUNT<=CBLINKINT-1;
		elsif(clk' event and clk='1')then
			if(VCOMP='1')then
				if(CICOUNT=0)then
					CURF<=not CURF;
					CICOUNT<=CBLINKINT-1;
				else
					CICOUNT<=CICOUNT-1;
				end if;
			end if;
		end if;
	end process;

	process(clk,rstn)begin
		if(rstn='0')then
			BLKF<='0';
			BICOUNT<=BLINKINT-1;
		elsif(clk' event and clk='1')then
			if(VCOMP='1')then
				if(BICOUNT=0)then
					BLKF<=not BLKF;
					BICOUNT<=BLINKINT-1;
				else
					BICOUNT<=BICOUNT-1;
				end if;
			end if;
		end if;
	end process;

	CURV<=CURE when CBLINK='0' else (CURE and CURF);

	process(clk,rstn)begin
		if(rstn='0')then
			HMODEC<='0';
			VMODEC<='0';
		elsif(clk' event and clk='1')then
			if(VCOMP='1')then
				HMODEC<=HMODE;
				VMODEC<=VMODE;
			end if;
		end if;
	end process;

	CHRLINES<=16 when VMODEC='1' else 20;

	process (clk,rstn)
	variable BNXTDOT0	:std_logic_vector(7 downto 0);
	variable BNXTDOT1	:std_logic_vector(7 downto 0);
	begin
		if(rstn='0')then
			NXTDOT0<=(others=>'0');
			NXTDOT1<=(others=>'0');
			NXTFGCLR<=(others=>'0');
			NXTBGCLR<=(others=>'0');
			NXTFS<='0';
			NXTBL<='0';
			TRAMADRb<=(others=>'0');
			FRAMADR<=(others=>'0');
			C_LOW<=0;
		elsif(clk' event and clk='1')then

-- Data	section
			if(DHCOMP='1')then
				if(VCOUNT>VIV)then
					if(C_LIN/=0)then
						TRAMADRb<=TRAMADRb-(HUVIS*2);
					else
						C_LOW<=C_LOW+1;
					end if;
				end if;
			end if;
			if(DVCOMP='1')then
				TRAMADRb<=(others=>'0');
				C_LOW<=0;
			end if;
			
			if(UCOUNT=4)then
					FRAMADR(11 downto 4)<=TRAMDAT;
				if(C_LIN<16)then
					FRAMADR(3 downto 0)<=conv_std_logic_vector(C_LIN,4);
				else
					FRAMADR(3 downto 0)<=(others=>'0');
				end if;
				if(VCOUNT>=VIV and HUCOUNT>=HIV)then
					TRAMADRb<=TRAMADRb+1;
				end if;
			elsif(UCOUNT=6)then
				if(VCOUNT>=VIV and HUCOUNT>=HIV)then
					if((TRAMDAT(3)='1' and BLKF='1') or (TRAMDAT(5)='1'))then
						BNXTDOT0:=(others=>'0');
						BNXTDOT1:=(others=>'0');
					else
						if(C_LIN<16)then
							BNXTDOT0:=FRAMDAT0;
							BNXTDOT1:=FRAMDAT1;
						else
							BNXTDOT0:=(others=>'0');
							BNXTDOT1:=(others=>'0');
						end if;
					end if;
					if(TRAMDAT(6)='1' and C_LIN=15)then	-- under line
						BNXTDOT0:=(others=>'1');
						BNXTDOT1:=(others=>'1');
					end if;
					if(CURV='1' and C_LOW=iCURL and C_COL=iCURC and (CURM='1' or C_LIN>(CHRLINES-CURLINE-1)))then
						NXTDOT0<=not BNXTDOT0;
						NXTDOT1<=not BNXTDOT1;
					else
						NXTDOT0<=BNXTDOT0;
						NXTDOT1<=BNXTDOT1;
					end if;
					NXTFGCLR<=TRAMDAT(2 downto 0);
					NXTBGCLR<=TRAMDAT(6 downto 4);
					NXTBL<=TRAMDAT(3);
					NXTFS<=TRAMDAT(7);
					TRAMADRb<=TRAMADRb+1;
				else
					NXTDOT0<=(others=>'0');
					NXTDOT1<=(others=>'0');
					NXTFGCLR<=(others=>'0');
					NXTBGCLR<=(others=>'0');
					NXTBL<='0';
					NXTFS<='0';
				end if;
			end if;
		end if;
	end process;

	TRAMADR<=TRAMADRb;

-- Display driver section
	process(clk,rstn)begin
		if(rstn='0')then
			BITOUT<='0';
			FGCOLOR<=(others=>'0');
			BGCOLOR<=(others=>'0');
			BLINK<='0';
			CURDOT<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(HMODEC='1')then
				if(UCOUNT=0)then
					if(NXTFS='0')then
						BITOUT<=NXTDOT0(7);
						CURDOT<=NXTDOT0;
					else
						BITOUT<=NXTDOT1(7);
						CURDOT<=NXTDOT1;
					end if;
					FGCOLOR<=NXTFGCLR;
					BGCOLOR<=NXTBGCLR;
					BLINK<=NXTBL;
				else
					BITOUT<=CURDOT(6);
					CURDOT<=CURDOT(6 downto 0) & '0';
				end if;
			else
				if(UCOUNT=0 and (HUCOUNT mod 2)=1)then
					if(NXTFS='0')then
						BITOUT<=NXTDOT0(7);
						CURDOT<=NXTDOT0;
					else
						BITOUT<=NXTDOT1(7);
						CURDOT<=NXTDOT1;
					end if;
					FGCOLOR<=NXTFGCLR;
					BGCOLOR<=NXTBGCLR;
					BLINK<=NXTBL;
				elsif((UCOUNT mod 2)=0)then
					BITOUT<=CURDOT(6);
					CURDOT<=CURDOT(6 downto 0) & '0';
				end if;
			end if;
		end if;
	end process;


end MAIN;
					
