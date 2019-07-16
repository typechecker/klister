{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ViewPatterns #-}
module SplitCore where

import Control.Lens hiding (List, children)
import Control.Monad.Except
import Control.Monad.Writer

import Data.Unique
import Data.Map (Map)
import qualified Data.Map as Map

import Core
import PartialCore

newtype SplitCorePtr = SplitCorePtr Unique
  deriving (Eq, Ord)

newSplitCorePtr :: IO SplitCorePtr
newSplitCorePtr = SplitCorePtr <$> newUnique

data SplitCore = SplitCore
  { _splitCoreRoot        :: SplitCorePtr
  , _splitCoreDescendants :: Map SplitCorePtr (CoreF SplitCorePtr)
  }
makeLenses ''SplitCore

unsplit :: SplitCore -> PartialCore
unsplit (SplitCore {..}) = PartialCore $ go _splitCoreRoot
  where
    go :: SplitCorePtr -> Maybe (CoreF PartialCore)
    go ptr = do
      this <- Map.lookup ptr _splitCoreDescendants
      return (fmap (PartialCore . go) this)

split :: PartialCore -> IO SplitCore
split partialCore = do
  root <- newSplitCorePtr
  ((), childMap) <- runWriterT $ go root (unPartialCore partialCore)
  return $ SplitCore root childMap
  where
    go ::
      SplitCorePtr -> Maybe (CoreF PartialCore) ->
      WriterT (Map SplitCorePtr (CoreF SplitCorePtr)) IO ()
    go _     Nothing = pure ()
    go place (Just c) = do
      children <- flip traverse c $ \p -> do
        here <- liftIO newSplitCorePtr
        go here (unPartialCore p)
        pure here
      tell $ Map.singleton place children