library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Simple successive cancellation decoder for a length-2 polar code.
-- The decoder consumes two log-likelihood ratios (LLRs) provided
-- as signed fixed-point numbers and produces the corresponding
-- decoded bits in natural order. Frozen bits can be forced through
-- the "frozen" input vector.
entity sc_decoder is
  generic (
    LLR_WIDTH : positive := 8
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    start        : in  std_logic;  -- Assert for one cycle to launch a decode
    llr_a        : in  signed(LLR_WIDTH-1 downto 0);
    llr_b        : in  signed(LLR_WIDTH-1 downto 0);
    frozen       : in  std_logic_vector(1 downto 0); -- "1" marks a frozen bit
    decoded_bits : out std_logic_vector(1 downto 0);
    valid        : out std_logic
  );
end entity sc_decoder;

architecture rtl of sc_decoder is
  type state_t is (idle, bit0, bit1);
  signal state        : state_t := idle;
  signal llr_a_reg    : signed(LLR_WIDTH-1 downto 0) := (others => '0');
  signal llr_b_reg    : signed(LLR_WIDTH-1 downto 0) := (others => '0');
  signal bit0_dec     : std_logic := '0';
  signal bit1_dec     : std_logic := '0';
  signal bits_reg     : std_logic_vector(1 downto 0) := (others => '0');
  signal valid_reg    : std_logic := '0';

  function sc_f(
    a : signed;
    b : signed
  ) return signed is
    variable abs_a  : signed(a'length-1 downto 0);
    variable abs_b  : signed(a'length-1 downto 0);
    variable min_ab : signed(a'length-1 downto 0);
    variable result : signed(a'length-1 downto 0);
  begin
    abs_a  := abs(a);
    abs_b  := abs(b);
    if abs_a < abs_b then
      min_ab := abs_a;
    else
      min_ab := abs_b;
    end if;

    if (a(a'high) xor b(b'high)) = '1' then
      result := -min_ab;
    else
      result := min_ab;
    end if;
    return result;
  end function;

  function sc_g(
    a : signed;
    b : signed;
    u : std_logic
  ) return signed is
    variable result : signed(a'length-1 downto 0);
  begin
    if u = '0' then
      result := b + a;
    else
      result := b - a;
    end if;
    return result;
  end function;

begin
  decoded_bits <= bits_reg;
  valid        <= valid_reg;

  process(clk)
    variable f_val : signed(LLR_WIDTH-1 downto 0);
    variable g_val : signed(LLR_WIDTH-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state     <= idle;
        llr_a_reg <= (others => '0');
        llr_b_reg <= (others => '0');
        bit0_dec  <= '0';
        bit1_dec  <= '0';
        bits_reg  <= (others => '0');
        valid_reg <= '0';
      else
        valid_reg <= '0';
        case state is
          when idle =>
            if start = '1' then
              llr_a_reg <= llr_a;
              llr_b_reg <= llr_b;
              state     <= bit0;
            end if;

          when bit0 =>
            f_val := sc_f(llr_a_reg, llr_b_reg);
            if frozen(0) = '1' then
              bit0_dec <= '0';
            elsif f_val >= to_signed(0, f_val'length) then
              bit0_dec <= '0';
            else
              bit0_dec <= '1';
            end if;
            state <= bit1;

          when bit1 =>
            g_val := sc_g(llr_a_reg, llr_b_reg, bit0_dec);
            if frozen(1) = '1' then
              bit1_dec <= '0';
            elsif g_val >= to_signed(0, g_val'length) then
              bit1_dec <= '0';
            else
              bit1_dec <= '1';
            end if;
            bits_reg  <= bit0_dec & bit1_dec;
            valid_reg <= '1';
            state     <= idle;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;
