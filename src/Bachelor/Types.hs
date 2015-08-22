{-
 - A Set of types to describe Events that can be displayed within edenTv
 -}
{-# LANGUAGE TemplateHaskell #-}

module Bachelor.Types where

import Control.Lens
import qualified Data.HashMap.Strict as M
import Data.Word
import GHC.RTS.Events (ThreadId, MachineId, ProcessId, Timestamp)
-- The GUIEvent type describes events that can be displayed within the
-- edentv GUI. All of these have a specified starting time and duration
-- | describes the current state of the RTS at the current moment in time

type Time = Word64

data ProcessState = ProcessState {
    p_parent    :: MachineId,
    p_state     :: RunState,
    p_timestamp :: Timestamp,
    p_tRunning  :: Int,
    p_tRunnable :: Int,
    p_tBlocked  :: Int,
    p_tIdle     :: Int
    }

data MachineState = MachineState {
    m_state     :: RunState,
    m_timestamp :: Timestamp,
    m_tRunning  :: Int,
    m_tRunnable :: Int,
    m_tBlocked  :: Int,
    m_tIdle     :: Int
    } | PreMachine

data ThreadState  = ThreadState {
    t_parent      :: ProcessId,
    t_state       :: RunState,
    t_timestamp   :: Timestamp
    }

type ThreadMap    = M.HashMap ThreadId ThreadState
type ProcessMap   = M.HashMap ProcessId ProcessState

data RunState = Idle | Running | Blocked | Runnable
    deriving (Show, Eq)

stateToInt :: RunState -> Int
stateToInt Idle     = 0
stateToInt Running  = 1
stateToInt Blocked  = 2
stateToInt Runnable = 3

data RTSState = RTSState {
    machines  :: MachineState,
    processes :: ProcessMap,
    threads   :: ThreadMap
    }

data MtpType = Machine MachineId | Process ProcessId | Thread ThreadId deriving Show

startingState :: RTSState
startingState = RTSState PreMachine M.empty M.empty

{- auxiliary functions for manipulation RTSState -}


{- Types for events that can be written to the database. -}
data GUIEvent = GUIEvent{
    mtpType   :: MtpType,
    startTime :: Word64,
    duration  :: Word64,
    state     :: RunState
    } | NewMachine MachineId | NewProcess MachineId ProcessId

--  | The Interface for reading/writing the data from disk.
class IOEventData a where
    readEvent  :: IOEventData a => a
        -> Integer -- ^ start time (in ns)
        -> Integer -- ^ end time (in ns)
        -> Integer -- ^ resolution (in ns). States smaller than this will not
                   -- be retreived from disk.
        -> IO [GUIEvent]
    -- | writes a single Event to Disk
    writeEvent :: IOEventData a => a -> GUIEvent -> IO()

{- auxiliary functions for detecting wether the state has changed, and
 - which events need to be written out to the database -}

generateGUIEvents :: RTSState -> RTSState -> [GUIEvent]
generateGUIEvents oldRts newRts = undefined

