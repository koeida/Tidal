{-# LANGUAGE OverloadedStrings #-}

module Sound.Tidal.CoreTest where

import Test.Microspec

import Prelude hiding ((<*), (*>))

import Data.Ratio
import Data.List (sort)

import Sound.Tidal.Core
import Sound.Tidal.Pattern
import Sound.Tidal.Utils

run :: Microspec ()
run =
  describe "Sound.Tidal.Core" $ do
    describe "append" $ do
      it "can switch between the cycles from two pures" $ do
        (queryArc (append (pure "a") (pure "b")) (0,5)) `shouldBe` [(((0,1), (0,1)), "a"),
                                                                    (((1,2), (1,2)), "b"),
                                                                    (((2,3), (2,3)), "a"),
                                                                    (((3,4), (3,4)), "b"),
                                                                    (((4,5), (4,5)), "a")
                                                                   ]

    describe "cat" $ do
      it "can switch between the cycles from three pures" $ do
        queryArc (cat [pure "a", pure "b", pure "c"]) (0,5) `shouldBe` [(((0,1), (0,1)), "a"),
                                                                        (((1,2), (1,2)), "b"),
                                                                        (((2,3), (2,3)), "c"),
                                                                        (((3,4), (3,4)), "a"),
                                                                        (((4,5), (4,5)), "b")
                                                                       ]

    describe "fastCat" $ do
      it "can switch between the cycles from three pures inside one cycle" $ do
        it "1" $ queryArc (fastCat [pure "a", pure "b", pure "c"]) (0,1)
          `shouldBe` [(((0,1/3),   (0,1/3)),   "a"),
                      (((1/3,2/3), (1/3,2/3)), "b"),
                      (((2/3,1),   (2/3,1)),   "c")
                     ]
        it "5/3" $ queryArc (fastCat [pure "a", pure "b", pure "c"]) (0,5/3)
          `shouldBe` [(((0,1/3),   (0,1/3)),   "a"),
                      (((1/3,2/3), (1/3,2/3)), "b"),
                      (((2/3,1),   (2/3,1)),   "c"),
                      (((1,4/3),   (1,4/3)),   "a"),
                      (((4/3,5/3), (4/3,5/3)), "b")
                     ]
      it "works with zero-length queries" $ do
        it "0" $
          queryArc (fastCat [pure "a", pure "b"]) (0,0)
            `shouldBe` [(((0,0.5), (0,0)), "a")]
        it "1/3" $
          queryArc (fastCat [pure "a", pure "b"]) (1%3,1%3)
            `shouldBe` [(((0,0.5), (1%3,1%3)), "a")]

    describe "rev" $ do
      it "mirrors events" $ do
        let forward = fastCat [fastCat [pure 7, pure 8], pure 9] :: Pattern Int
            backward = fastCat [pure 9, fastCat [pure 8, pure 7]]
        -- sort the events into time order to compare them
        (sort $ queryArc (rev forward) (0,1)) `shouldBe` (sort $ queryArc (backward) (0,1))

      it "returns the original if you reverse it twice" $ do
        let x = fastCat [fastCat [pure 7, pure 8], pure 9] :: Pattern Int
        (queryArc (rev $ rev x) (0,5)) `shouldBe` (queryArc x (0,5))

    describe "compress" $ do
      it "squashes cycles to the start of a cycle" $ do
        let p = compress (0, 0.5) $ fastCat [pure 7, pure 8] :: Pattern Int
        (queryArc p (0,1)) `shouldBe` [(((0,0.25),  (0,0.25)),   7),
                                       (((0.25,0.5),(0.25,0.5)), 8)
                                      ]
      it "squashes cycles to the end of a cycle" $ do
        let p = compress (0.5,1) $ fastCat [pure 7, pure 8] :: Pattern Int
        (queryArc p (0,1)) `shouldBe` [(((0.5,0.75),  (0.5,0.75)), 7 :: Int),
                                       (((0.75,1),    (0.75,1)),   8)
                                      ]
      it "squashes cycles to the middle of a cycle" $ do
        let p = compress (0.25,0.75) $ fastCat [pure 7, pure 8]
        (queryArc p (0,1)) `shouldBe` [(((0.25,0.5),  (0.25,0.5)), 7 :: Int),
                                       (((0.5,0.75),  (0.5,0.75)), 8)
                                      ]

    describe "saw" $ do
      it "goes from 0 up to 1 every cycle" $ do
        it "0" $
          (queryArc saw (0,0))    `shouldBe` [(((0,0), (0,0)),    0 :: Float)]
        it "0.25" $
          (queryArc saw (0.25,0.25)) `shouldBe` [(((0.25,0.25), (0.25,0.25)), 0.25 :: Float)]
        it "0.5" $
          (queryArc saw (0.5,0.5))  `shouldBe` [(((0.5,0.5), (0.5,0.5) ), 0.5 :: Float)]
        it "0.75" $
          (queryArc saw (0.75,0.75)) `shouldBe` [(((0.75,0.75), (0.75,0.75)), 0.75 :: Float)]
      it "can be added to" $ do
        (map eventValue $ queryArc ((+1) <$> saw) (0.5,0.5)) `shouldBe` [1.5 :: Float]
      it "works on the left of <*>" $ do
        (queryArc ((+) <$> saw <*> pure 3) (0,1))
          `shouldBe` [(((0,1), (0,1)), 3 :: Float)]
      it "works on the right of <*>" $ do
        (queryArc ((fast 4 $ pure (+3)) <*> saw) (0,1))
          `shouldBe` [(((0,0.25), (0,0.25)), 3 :: Float),
                      (((0.25,0.5), (0.25,0.5)), 3.25),
                      (((0.5,0.75), (0.5,0.75)), 3.5),
                      (((0.75,1), (0.75,1)), 3.75)
                     ]
      it "can be reversed" $ do
        it "works with whole cycles" $
          (queryArc (rev saw) (0,1))
            `shouldBe` [(((0,1), (0,1)), 0.5 :: Float)]
        it "works with half cycles" $
          (queryArc (rev saw) (0,0.5))
            `shouldBe` [(((0,0.5), (0,0.5)), 0.75 :: Float)]
        it "works with inset points" $
          (queryArc (rev saw) (0.25,0.25))
            `shouldBe` [(((0.25,0.25), (0.25,0.25)), 0.75 :: Float)]
