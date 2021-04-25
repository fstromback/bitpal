defmodule BitPal.Crypto.ECurve do
  @moduledoc """
  This module implements the basics for ECC (Elliptic Curve Cryptography) so that
  we can use these operations to derive keys, and perform other cryptographic
  operations.

  Note: This implementation is *not* designed to be safe from back-channels etc. It is intended to
  be used to derive public keys from public seeds etc.
  """

  defmodule Curve do
    @moduledoc """
    A curve:
    p is the finite field (note, knowing which "bases" are used can be used to speed up computations)
    a and b define the curve (y^2 = x^3 + ax + b)
    g is the base point (uncompressed form)
    n is the order of G
    h is the cofactor of G
    """
    defstruct p: 0,
              a: 0,
              b: 0,
              g: 0,
              n: 0,
              h: 0
  end

  defmodule Point do
    @moduledoc """
    A point on an elliptic curve.

    Note: The point nil nil is the infinity point.
    """
    defstruct x: nil, y: nil
  end

  @doc """
  Get the curve used by Bitcoin/Bitcoin Cash: the secp256k1 (http://www.secg.org/sec2-v2.pdf)
  """
  def default() do
    %Curve{
      p: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_FFFFFC2F,
      a: 0x0,
      b: 0x7,
      # This is the compressed version.
      # g: 0x02_79BE667E_F9DCBBAC_55A06295_CE870B07_029BFCDB_2DCE28D9_59F2815B_16F81798,
      # Note: When printed somewhere, these points start either with 0x02 (for compressed)
      # or 0x04 (for uncompressed). We don't shave those away, that needs to be handled
      # somewhere else.
      g: %Point{
        x: 0x79BE667E_F9DCBBAC_55A06295_CE870B07_029BFCDB_2DCE28D9_59F2815B_16F81798,
        y: 0x483ADA77_26A3C465_5DA4FBFC_0E1108A8_FD17B448_A6855419_9C47D08F_FB10D4B8
      },
      n: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141,
      h: 0x01
    }
  end

  @doc """
  Compute the polynomial defined by a particular curve for a given value for x.
  """
  def compute(curve, x) do
    rem(x * x * x + curve.a * x + curve.b, curve.p)
  end

  @doc """
  Check so that a point lies on an EC. Returns 0 if all is well.
  """
  def check(curve, pt) do
    if pt == %Point{} do
      0
    else
      rem(compute(curve, pt.x) - pt.y * pt.y, curve.p)
    end
  end

  @doc """
  Add two point on a curve.

  Implemented as per: https://www.secg.org/sec1-v2.pdf (2.2.1)
  """
  def add(curve, a, b) do
    cond do
      a == %Point{} ->
        b

      b == %Point{} ->
        a

      a == b ->
        slope = div(curve.p, 3 * a.x * a.x + curve.a, 2 * a.y)
        x = slope * slope - 2 * a.x

        %Point{
          x: rem(x, curve.p),
          y: rem(slope * (a.x - x) - a.y, curve.p)
        }

      a.x == b.x ->
        # Observation, if a != b, then we know that a.y == -b.y
        %Point{}

      true ->
        slope = div(curve.p, b.y - a.y, b.x - a.x)
        x = slope * slope - a.x - b.x

        %Point{
          x: rem(x, curve.p),
          y: rem(slope * (a.x - x) - a.y, curve.p)
        }
    end
  end

  @doc """
  Multiply a point with an integer.
  """
  def mul(curve, point, number) do
    cond do
      number == 0 ->
        %Point{}

      number == 1 ->
        point

      rem(number, 2) == 0 ->
        p = mul(curve, point, div(number, 2))
        add(curve, p, p)

      true ->
        add(curve, point, mul(curve, point, number - 1))
    end
  end

  @doc """
  Generate elements based on the generator of a curve.
  """
  def generate(curve, number) do
    mul(curve, curve.g, number)
  end

  # Find multiplicative inverse of a and b.
  # This is done by solving the diophantine equation:
  # a = b*x + modulo*y, where x and y are integers.
  defp div(modulo, a, b) do
    {sol_x, _sol_y} = diophantine(b, modulo, a)
    sol_x
  end

  # Solve the diophantine equation: a * x + b * y = sum
  defp diophantine(a, b, sum) do
    cond do
      b == 0 ->
      # Easy case:
      # x = sum / a iff sum mod a != 0
      if rem(sum, a) == 0 do
        {div(sum, a), 0}
      else
        raise("No solution")
      end

      a == 0 ->
        # Easy case, same as above
      if rem(sum, b) == 0 do
        {0, div(sum, b)}
      else
        raise("No solution")
      end

      true ->
        # Compute the form: a = z * b + r
        # We can also say: r = a - z * b
        z = div(a, b)
        r = rem(a, b)

        # Solve the new equation, b*x + r*y = sum
        {sol_x, sol_y} = diophantine(b, r, sum)

        # We know: r = a - z * b
        # Substitution gives: b*x + (a - z*b)*y = sum
        # Which equals: b*x + a*y - z*b*y = sum <=> a*y + b*(x - z*y)
        {sol_y, sol_x - sol_y * z}
    end
  end
end
