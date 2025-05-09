{-# OPTIONS_GHC -Wall #-}
-- The above pragma enables all warnings

module Task3 where

import Task2 (Stream(..), fromList)
import Data.Ratio (Ratio, numerator)
import Prelude hiding ((**))
-- | Power series represented as infinite stream of coefficients
-- 
-- For following series
--   @a0 + a1 * x + a2 * x^2 + ...@
-- coefficients would be
--   @a0, a1, a2, ...@
--
-- Usage examples:
--
-- >>> coefficients (x + x ^ 2 + x ^ 4)
-- [0,1,1,0,1,0,0,0,0,0]
-- >>> coefficients ((1 + x)^5)
-- [1,5,10,10,5,1,0,0,0,0]
-- >>> coefficients (42 :: Series Integer)
-- [42,0,0,0,0,0,0,0,0,0]
--
newtype Series a = Series
  { coefficients :: Stream a
  -- ^ Returns coefficients of given power series
  --
  -- For following series
  --   @a0 + a1 * x + a2 * x^2 + ...@
  -- coefficients would be
  --   @a0, a1, a2, ...@
  }


-- | Power series corresponding to single @x@
--
-- First 10 coefficients:
--
-- >>> coefficients x
-- [0,1,0,0,0,0,0,0,0,0]
--
x :: Num a => Series a
x = Series (fromList 0 [0,1])


mapStream :: (a -> b) -> Stream a -> Stream b
mapStream f (Stream a as) = Stream (f a) (mapStream f as)

addStreams :: Num a => Stream a -> Stream a -> Stream a
addStreams (Stream a as) (Stream b bs) = Stream (a + b) (addStreams as bs)

subStreams :: Num a => Stream a -> Stream a -> Stream a
subStreams (Stream a as) (Stream b bs) = Stream (a - b) (subStreams as bs)
-- | Multiplies power series by given number
-- 
-- For following series
--   @a0 + a1 * x + a2 * x^2 + ...@
-- coefficients would be
--   @a0, a1, a2, ...@
--
-- Usage examples:
--
-- >>> coefficients (2 *: (x + x ^ 2 + x ^ 4))
-- [0,2,2,0,2,0,0,0,0,0]
-- >>> coefficients (2 *: ((1 + x)^5))
-- [2,10,20,20,10,2,0,0,0,0]
--

infixl 7 *:
(**) :: Num a => a -> Stream a -> Stream a 
(**) n (Stream a b) = Stream (n*a) (n ** b)

(*:) :: Num a => a -> Series a -> Series a
(*:) n (Series a)= Series (n ** a)
instance Num a => Num (Series a) where
  fromInteger n      = Series (fromList 0 [fromInteger n])
  negate (Series s)  = Series (mapStream negate s)
  (Series s1) + (Series s2) = Series (addStreams s1 s2)
  (Series s1) * (Series s2) = Series (mul s1 s2)
    where
      -- power-series multiplication: (a0 + x A') * (b0 + x B')
      mul (Stream a0 as) sb@(Stream b0 bs) =
        let headCoeff = a0 * b0
            tailStream = addStreams (mapStream (a0 *) bs) (mul as sb)
        in  Stream headCoeff tailStream
  abs = id
  signum _ = Series (fromList 0 [1])


instance Fractional a => Fractional (Series a) where
  fromRational r   = Series (fromList 0 [fromRational r])
  (Series sa) / (Series sb) = Series (divide sa sb)
    where
      -- power-series division A/B = c0 + x*(rest/B)
      divide (Stream a0 as) s@(Stream b0 bs) =
        let c0 = a0 / b0
            remainder = subStreams as (mapStream (c0 *) bs)
            tailStream = divide remainder s
        in  Stream c0 tailStream

-- | Helper function for producing integer
-- coefficients from generating function
-- (assuming denominator of 1 in all coefficients)
--
-- Usage example:
--
-- >>> gen $ (2 + 3 * x)
-- [2,3,0,0,0,0,0,0,0,0]
--
gen :: Series (Ratio Integer) -> Stream Integer
gen (Series s) = mapStream numerator s

-- | Returns infinite stream of ones
--
-- First 10 elements:
--
-- >>> ones
-- [1,1,1,1,1,1,1,1,1,1]
--
ones :: Stream Integer
ones = gen (1 / (1 - x))

-- | Returns infinite stream of natural numbers (excluding zero)
--
-- First 10 natural numbers:
--
-- >>> nats
-- [1,2,3,4,5,6,7,8,9,10]
--
nats :: Stream Integer
nats = gen (1 / ((1 - x) * (1 - x)))

-- | Returns infinite stream of fibonacci numbers (starting with zero)
--
-- First 10 fibonacci numbers:
--
-- >>> fibs
-- [0,1,1,2,3,5,8,13,21,34]
--
fibs :: Stream Integer
fibs = gen (x / (1 - x - x * x))

