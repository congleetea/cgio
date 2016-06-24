--
#+BEGIN_SRC
rs0:PRIMARY> show dbs
datapoints  0.000GB
local       0.000GB
rs0:PRIMARY> use local
switched to db local
rs0:PRIMARY> show collections
me
oplog.rs
replset.election
startup_log
system.replset
rs0:PRIMARY> 
db.oplog.rs.find()
{ "ts" : Timestamp(1466756319, 1), "h" : NumberLong("-963420000355129263"), "v" : 2, "op" : "n", "ns" : "", "o" : { "msg" : "initiating set" } }
{ "ts" : Timestamp(1466756320, 1), "t" : NumberLong(1), "h" : NumberLong("-4966851510130475513"), "v" : 2, "op" : "n", "ns" : "", "o" : { "msg" : "new primary" } }
{ "ts" : Timestamp(1466756343, 1), "t" : NumberLong(1), "h" : NumberLong("946287662918931336"), "v" : 2, "op" : "n", "ns" : "", "o" : { "msg" : "Reconfig set", "version" : 2 } }
{ "ts" : Timestamp(1466756347, 1), "t" : NumberLong(1), "h" : NumberLong("-8561243952684830309"), "v" : 2, "op" : "n", "ns" : "", "o" : { "msg" : "Reconfig set", "version" : 3 } }
{ "ts" : Timestamp(1466761697, 1), "t" : NumberLong(1), "h" : NumberLong("503637440048404113"), "v" : 2, "op" : "c", "ns" : "datapoints.$cmd", "o" : { "create" : "databases" } }
{ "ts" : Timestamp(1466761697, 2), "t" : NumberLong(1), "h" : NumberLong("6798283011398940312"), "v" : 2, "op" : "i", "ns" : "datapoints.databases", "o" : { "_id" : ObjectId("576d01e1973d7622c2a9a20b"), "x" : 1, "y" : 1 } }
{ "ts" : Timestamp(1466761746, 1), "t" : NumberLong(1), "h" : NumberLong("-6544695893650504856"), "v" : 2, "op" : "c", "ns" : "datapoints.$cmd", "o" : { "drop" : "databases" } }
{ "ts" : Timestamp(1466761788, 1), "t" : NumberLong(1), "h" : NumberLong("871103872333449783"), "v" : 2, "op" : "c", "ns" : "datapoints.$cmd", "o" : { "create" : "collection1" } }
{ "ts" : Timestamp(1466761788, 2), "t" : NumberLong(1), "h" : NumberLong("-8537663362253297549"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d023c973d7622c2a9a20c"), "x" : 1, "y" : 1 } }
{ "ts" : Timestamp(1466762188, 1), "t" : NumberLong(1), "h" : NumberLong("-6059542614335668256"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03cc973d7622c2a9a20d"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762197, 1), "t" : NumberLong(1), "h" : NumberLong("8287119801061898350"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d5973d7622c2a9a20e"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762197, 2), "t" : NumberLong(1), "h" : NumberLong("-4966339317649638135"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d5973d7622c2a9a20f"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762198, 1), "t" : NumberLong(1), "h" : NumberLong("7786522553933687269"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d6973d7622c2a9a210"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762198, 2), "t" : NumberLong(1), "h" : NumberLong("1576960449529466156"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d7973d7622c2a9a211"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762199, 1), "t" : NumberLong(1), "h" : NumberLong("7879711748210825113"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d7973d7622c2a9a212"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762199, 2), "t" : NumberLong(1), "h" : NumberLong("2493029615457160808"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d7973d7622c2a9a213"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762200, 1), "t" : NumberLong(1), "h" : NumberLong("-4837120084819052492"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d8973d7622c2a9a214"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762200, 2), "t" : NumberLong(1), "h" : NumberLong("-3302938612025186314"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d8973d7622c2a9a215"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762200, 3), "t" : NumberLong(1), "h" : NumberLong("5119870559854300584"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d8973d7622c2a9a216"), "x" : 2, "y" : 1 } }
{ "ts" : Timestamp(1466762200, 4), "t" : NumberLong(1), "h" : NumberLong("9113416806552152802"), "v" : 2, "op" : "i", "ns" : "datapoints.collection1", "o" : { "_id" : ObjectId("576d03d8973d7622c2a9a217"), "x" : 2, "y" : 1 } }
Type "it" for more
rs0:PRIMARY> 
#+END_SRC 

