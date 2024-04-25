{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
module Kind (Kind(..), KindVar, newKindVar, kFun, KindStore) where

import Control.Lens
import Data.Data (Data)

import Unique

import Util.Store (Store)
import Util.Key

newtype KindVar = KindVar Unique
  deriving newtype (Eq, Ord, HasKey)
  deriving stock   Data


instance Show KindVar where
  show (KindVar i) = "(KindVar " ++ show (hashUnique i) ++ ")"

data Kind
  = KStar
  | KFun Kind Kind
  | KMetaVar KindVar
  deriving (Data, Eq, Show)
makePrisms ''Kind


newKindVar :: IO KindVar
newKindVar = KindVar <$> newUnique


kFun :: [Kind] -> Kind -> Kind
kFun args result = foldr KFun result args

newtype KindStore = KindStore (Store KindVar Kind)
  deriving newtype (Monoid, Semigroup, Show)

type instance Index KindStore = KindVar
type instance IxValue KindStore = Kind

instance Ixed KindStore where
  ix var f (KindStore env) = KindStore <$> ix var f env

instance At KindStore where
  at x f (KindStore env) = KindStore <$> at x f env

