{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Utils.Controller
  ( module Utils.Controller
  , module Types
  , Int64(..)
  , Entity(..)
  , liftIO
  ) where

import Servant
import Diener
import Data.Int
import Control.Lens
import Data.Monoid ((<>))
import Control.Exception.Lifted (SomeException (..), catch)
import Control.Monad.IO.Class (liftIO)
import Database.Persist
import Database.Persist.Postgresql
import Database.Esqueleto.Internal.Sql (SqlSelect)
import qualified Database.Esqueleto as E
import qualified Data.Hashable as HM
import qualified Data.HashMap.Strict as HM
import qualified Data.Text as T (pack)

import Types

class HasController a where
  resourceController :: a

instance (HasController a, HasController b) => HasController (a :<|> b) where
  resourceController = resourceController :<|> resourceController

class HasPermission a b where
  authorize :: SqlSelect () c => a -> Key b -> HandlerT IO c

runDb :: (MonadLogger (HandlerT IO), MonadError e (HandlerT IO))
      => ConnectionPool -> e -> SqlPersistT (HandlerT IO) a -> HandlerT IO a
runDb pool err q =
  catch (runSqlPool q pool) $ \(SomeException e) -> do
    $logError "runSqlPool failed."
    $logError $ "Error: " <> (T.pack . show) e
    throwError err

runQuery query = do
  pool <- asks db
  runDb pool ErrDatabaseQuery query

selectOne' e a = E.select a >>= safeHead e

selectOne a = E.select a >>= safeHead ErrNotFound

safeHead :: MonadError e m => e -> [a] -> m a
safeHead e l = maybe (throwError e) pure (l ^? _head)

collectionJoin :: (HM.Hashable a, Eq a) => [(a, b)] -> [(a, [b])]
collectionJoin xs = HM.toList $ HM.fromListWith (++) [(k, [v]) | (k, v) <- xs]
