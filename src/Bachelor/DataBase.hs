 {-# LANGUAGE OverloadedStrings #-}
module Bachelor.DataBase where

{-
 - Provides a interface for reading/writing RTS State Events to and from
 - a database.
 - -}

--instance IOEventData where

import Bachelor.Types
import Database.PostgreSQL.Simple
import GHC.RTS.Events
import qualified Data.HashMap.Strict as M
import Control.Applicative

myConnectInfo :: ConnectInfo
myConnectInfo = defaultConnectInfo {
    connectPassword = "bohCh0mu"
    }

mkConnection = connect myConnectInfo

-- the information necessary for entering events into the database.
-- because the database should be able to contain multiple traces,
-- we keep a set of keys to uniquely identify the machines, processes and
-- threads within the current trace.

data DBInfo = DBInfo {
    db_traceKey   :: Int,
    db_machines   :: M.HashMap MachineId Int,
    db_processes  :: M.HashMap (MachineId,ProcessId) Int,
    db_threads    :: M.HashMap (MachineId,ProcessId,ThreadId) Int,
    db_connection :: Connection
    }

instance Show DBInfo where
    show dbi =
            "Trace ID : " ++ (show $ db_traceKey dbi) ++ "\n"
        ++  "Machines:  " ++ (show $ db_machines dbi)

-- when starting to parse a new file, we need to create a new connection,
-- and then insert a new trace into our list of traces, then store the trace_id
-- into a new DBInfo value.

insertTraceQuery :: Query
insertTraceQuery = "Insert Into Traces (filename, creation_date)\
    \values( ? , now()) returning trace_id;"

createDBInfo :: FilePath -> IO DBInfo
createDBInfo file = do
    conn <- mkConnection
    traceKey <- head <$> query conn insertTraceQuery (Only file)
    case traceKey of
        Only key -> do
            putStrLn $ show $ (key :: Int)
            return $ DBInfo {
                db_traceKey   = key,
                db_machines   = M.empty,
                db_processes  = M.empty,
                db_threads    = M.empty,
                db_connection = conn
                }
        _       -> error "trace insertion failed"

insertMachineQuery :: Query
insertMachineQuery = "Insert Into Machines(num,trace_id)\
    \values( ? , ? ) returning machine_id;"

insertMachine :: DBInfo -> MachineId-> IO DBInfo
insertMachine dbi mid = do
    let conn     = db_connection dbi
        traceKey = db_traceKey   dbi
    machineKey <- head <$> query conn insertMachineQuery (mid, traceKey)
    case machineKey of
        Only key -> do
            return $ dbi {
                db_machines   = M.insert mid key (db_machines dbi)
                }
        _       -> error "machine insertion failed"

insertProcessQuery :: Query
insertProcessQuery =
    "Insert Into Processes(num,machine_id)\
        \values( ? , ? ) returning process_id;"

insertProcess :: DBInfo -> MachineId -> ProcessId -> IO DBInfo
insertProcess dbi mid pid = do
    let conn       = db_connection dbi
        machineKey = (db_machines dbi) M.! mid
    processKey <- head <$> query conn insertProcessQuery (pid, machineKey)
    case processKey of
        Only key -> do
            return $ dbi {
                db_processes   = M.insert (mid,pid) key (db_processes dbi)
                }
        _       -> error "machine insertion failed"

insertThreadQuery :: Query
insertThreadQuery =
    "Insert into Threads()"


-- insertion functions for different Events
insertEvent :: DBInfo -> Event -> IO DBInfo
insertEvent dbi (Event ts spec) =
    case spec of
        CreateMachine realtime m_id -> do
            return dbi
        -- events not implemented
        _                  -> do
            return dbi
