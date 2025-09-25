library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add100bits is
    port (
        a    : in  std_logic_vector(99 downto 0);
        b    : in  std_logic_vector(99 downto 0);
        sum  : out std_logic_vector(100 downto 0)
    );
end entity add100bits;

architecture rtl of add100bits is
begin
    process (a, b)
        variable unsigned_a : unsigned(a'range);
        variable unsigned_b : unsigned(b'range);
        variable result     : unsigned(sum'range);
    begin
        unsigned_a := unsigned(a);
        unsigned_b := unsigned(b);
        result     := resize(unsigned_a, sum'length) + resize(unsigned_b, sum'length);
        sum        <= std_logic_vector(result);
    end process;
end architecture rtl;
