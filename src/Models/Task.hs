module Models.Task where

import qualified Data.ByteString.Lazy as B
data Task = Task {
    taskId        :: Int,
    configuration :: String,
    files         :: [File],
    tests         :: [Test]
} deriving Show

data File = File {
  name    :: String,
  content :: B.ByteString
} deriving Show

data Test = Test {
  input     :: String,
  output    :: String,
  timeLimit :: Int,
  ramLimit  :: Int
} deriving Show

data TaskResult = TaskResult {
  resultId       :: Int,
  compilationLog :: String,
  testResults    :: [TestResult]
} deriving Show

data TestResult = TestResult {
  status        :: Status,
  executionTime :: Int,
  ramUsage      :: Int
} deriving Show

data Status = OK | RTE | MEM | TLE | ANS | CME deriving Show
