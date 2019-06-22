{-# LANGUAGE DeriveFunctor #-}
module Syntax where

import qualified Data.Set as Set
import Data.Text (Text)

data SrcPos = SrcPos Int Int
  deriving (Eq, Show)

data SrcLoc = SrcLoc FilePath SrcPos SrcPos
  deriving (Eq, Show)

-- Int should be enough for now - consider bumping to something like int64
newtype Scope = Scope Int
  deriving (Eq, Ord, Show)

type ScopeSet = Set.Set Scope

noScopes :: ScopeSet
noScopes = Set.empty


data Stx a = Stx ScopeSet SrcLoc a


data ExprF a
  = Id Text
  | List [a]
  | Vec [a]
  deriving Functor


newtype Syntax =
  Syntax (Stx (ExprF Syntax))

type Ident = Stx Text

