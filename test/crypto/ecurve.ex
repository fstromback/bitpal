defmodule CashaddressTest do
  use ExUnit.Case, async: true
  alias BitPal.Crypto.ECurve

  test "basic arithmetics" do
    curve = ECurve.default()

    a = curve.g
    b = ECurve.add(curve, a, a)
    c = ECurve.add(curve, a, b)
    d = ECurve.add(curve, b, a)
    e = ECurve.add(curve, c, %ECurve.Point{})
    f = ECurve.add(curve, %ECurve.Point{}, c)

    mul0 = ECurve.mul(curve, curve.g, 0)
    mul1 = ECurve.mul(curve, curve.g, 1)
    mul2 = ECurve.mul(curve, curve.g, 2)
    mul3 = ECurve.mul(curve, curve.g, 3)

    # IO.inspect(a)
    # IO.inspect(ECurve.check(curve, a))
    # IO.inspect(b)
    # IO.inspect(ECurve.check(curve, b))
    # IO.inspect(c)
    # IO.inspect(ECurve.check(curve, c))
    # IO.inspect(d)
    # IO.inspect(ECurve.check(curve, d))

    assert ECurve.check(curve, a) == 0
    assert ECurve.check(curve, b) == 0
    assert ECurve.check(curve, c) == 0
    assert ECurve.check(curve, d) == 0
    assert c == d
    assert e == c
    assert f == c
    assert mul0 == %ECurve.Point{}
    assert mul1 == a
    assert mul2 == b
    assert mul3 == d
  end
end
