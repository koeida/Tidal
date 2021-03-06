{-# LANGUAGE OverloadedStrings #-}

import Test.Microspec

import Sound.Tidal.CoreTest
import Sound.Tidal.ParseTest
import Sound.Tidal.PatternTest
import Sound.Tidal.UITest
import Sound.Tidal.UtilsTest

main :: IO ()
main = microspec $ do
  Sound.Tidal.CoreTest.run
  Sound.Tidal.ParseTest.run
  Sound.Tidal.PatternTest.run
  Sound.Tidal.UITest.run
  Sound.Tidal.UtilsTest.run
