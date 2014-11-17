{-# LANGUAGE BangPatterns               #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE TemplateHaskell            #-}

module Network.PagerDuty.Types
where

import           Control.Applicative
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Attoparsec.ByteString.Char8 (takeByteString)
import           Data.ByteString                  (ByteString)
import           Data.ByteString.Builder
import           Data.ByteString.Conversion
import qualified Data.HashMap.Strict              as H
import           Data.String
import           Data.Text                        (Text)
import           Data.Text.Encoding               (encodeUtf8, decodeUtf8)
import           GHC.Generics
import           Network.HTTP.Client              (Manager)
import           Network.PagerDuty.Internal


data Env a
    = Env      !Manager
    | TokenEnv !Host !Token     !Manager
    | BasicEnv !Host !BasicAuth !Manager

type PagerDuty a b = ReaderT (Env a) IO b


newtype SubDomain = SubDomain { subDomain :: ByteString }
    deriving (Eq, Show, IsString)


data BasicAuth = BasicAuth !ByteString !ByteString
    deriving Eq

newtype Token = Token ByteString
    deriving (Eq, IsString)


data Authenticated a
data UnAuthenticated


type Host = ByteString


newtype Code = Code Integer
    deriving (Eq, Show, Generic)

instance FromJSON Code
instance ToJSON Code

message :: Code -> Text
message (Code c) = case c of
   2000 -> "Internal Error"
   2001 -> "Invalid Input Provided"
   2002 -> "Arguments Caused Error"
   2003 -> "Missing Arguments"
   2004 -> "Invalid 'since' or 'until' Parameter Values"
   2005 -> "Invalid Query Date Range"
   2006 -> "Authentication Failed"
   2007 -> "Account Not Found"
   2008 -> "Account Locked"
   2009 -> "Only HTTPS Allowed For This Call"
   2010 -> "Access Denied"
   2011 -> "The action requires a 'requester_id' to be specified"
   2012 -> "Your account is expired and cannot use the API"
   _    -> "Unrecognised error code"


data Error
    = Internal String
    | External
      { _message :: Text
      , _code    :: Code
      , _errors  :: [Text]
      }
    deriving (Eq, Show, Generic)

instance ToJSON   Error where toJSON    = gToJson   "_"
instance FromJSON Error where parseJSON = gFromJson "_"


newtype Key a = Key Text
    deriving (Eq, Show, Generic, IsString)

instance ToByteString (Key a) where
    builder (Key x) = byteString (encodeUtf8 x)

instance FromByteString (Key a) where
    parser = Key . decodeUtf8 <$> takeByteString

instance ToJSON   (Key a)
instance FromJSON (Key a)

data Service
data Incident

type ServiceKey  = Key Service
type IncidentKey = Key Incident


newtype Id a = Id Text
    deriving (Eq, Show, Generic, IsString)

instance ToJSON   (Id a)
instance FromJSON (Id a)

data Requester

type ServiceId   = Id Service
type RequesterId = Id Requester


data Empty = Empty

instance ToJSON   Empty where toJSON _ = object []
instance FromJSON Empty where
    parseJSON (Object !o) | H.null o  = pure Empty
                          | otherwise = mzero
    parseJSON _ = mzero
