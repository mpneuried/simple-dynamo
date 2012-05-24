simple-dynamo
===========

**simple-dynamo** is a abstraction layer to Jed Schmidt's [dynamo](https://github.com/jed/dynamo) Node.js driver.

It provides a absolute simple JSON-CRUD Interface without any knowledge of Dynamos specialties.

A special feature is the *combineTableTo* options for tables. It adds the ability to combine multiple models into one Dymamo-table, but use them separately in your application. So you have to pay only one throughput capacity.

*Written in coffee-script*

**INFO: all examples are written in coffee-script**

## Install

```
  npm install simple-dynamo@git://github.com/mpneuried/dynamo_connector.git
```

## Examples

### Initialize module:

first you have to define the connection and table attributes and get an instance of the simple-dynamo interface.

`new SimpleDynamo( connectionSettings, tables )`

####connection Settings

- **accessKeyId** : Your AWS access key id
- **secretAccessKey** : Your AWS secret access key
- **region** : The region your Dynamo-Tables will be placed 

####table Definition

An Object of Tables.  
The key you are using will be the key to get the table object.

Every object can have the following keys:

- **name** : *( `String` required )*  
Tablename for AWS
- **hashKey** : *( `String` required )*  
The hash key name of your ids/hashes
- **hashKeyType** : *( `String` optional: default = `S` )*  
The type of the `hashKey`. Possible values are: `S` = String and `N` = Numeric
- **rangeKey**: *( String optional )*  
The range key name of your range attribute. If not defined the table will be generated without the range methods
- **rangeKeyType**: *( `String` optional: default = `N` )*  
The type of the `rangeKey`. Possible values are: `S` = String and `N` = Numeric
- **fnCreateHash**: *( `Function` optional: default = `new UUID` )*  
Method to generate a custom hash key.  
- **combineTableTo**: *( `String` optional )*
Option to combine multiple models into one dynamo-table. Makes sense if you want to pay only one table. Combinations are not allowed for tables of different types ( Hash-table and HashRange-table ) and you have to use the same hashKey and rangeKey. The module will handle all interactions with the models transparent, so you only have to define this option.  
*Note:* If you use this feature and predefine the id/hash you have to add the `name` of the table in front of every id/hash.
- **overwriteExistingHash**: *( `Boolean` optional: default = true )*  
Overwrite a item on `create` of an existing hash. 
- **removeMissing**: *( `Boolean` optional: default = true )*  
On `true` during an update all keys not found in data will be removed. Otherwise it won't be touched.  
**Method Arguments**  
  - **attributes**: The given attributes on create  
  - **cb**: Callback method to pass the custom generates id/hash. `cb( "my-special-hash" )`
- **fnCreateRange**: *( `Function` optional: default = `current Timestamp` )*  
Method to generate a custom range key.  
**Method Arguments**  
  - **attributes**: The given attributes on create  
  - **cb**: Callback method to pass the custom generates id/hash. `cb( "my-special-range" )`
- **attributes**: *( `Array of Objects` required )*  
An array of attribute Objects. Which will be validated  
**Attributes keys**
  - **key**: *( `String` required )*  
  Column/Attribute name/key
  - **type**: *( `String` required )*  
  Datatype. possible values are `string` = String, `number` = Numeric and `array` = Array/Set of **Strings**
  - **required**: *( `Boolean` optional: default = `false` )*  
  Validate the attribute to be required. *( Not implemented yet ! )*
   
  
**Example**

```
# import module
SimpleDynamo = require "simple-dynamo"

# define connection settings
connectionSettings =
	accessKeyId: "-"
	secretAccessKey: "-"
	region: "eu-west-1"
	
# define tables
tables = 
	"Users":
		name: "users"
		hashKey: "id"

		attributes: [
			{ key: "name", type: "string", required: true }
			{ key: "email", type: "string" }
		]
		
	"Todos":
		name: "todos"
		hashKey: "id"
		rangeKey: "_t"
		rangeKeyType: "N"
		
		fnCreateHash: ( attributes, cb )=>
			cb( attributes.user_id )
			return
		
		attributes: [
			{ key: "title", type: "string", required: true }
			{ key: "done", type: "number" }
		]
	
	# example for a combined table usage
	"Combined1":
		name: "c1"
		hashKey:  "id"
		combineTableTo: "combined_hash"

		attributes: [
			{ key: "title", type: "string", required: true }
		]
	
	"Combined2":
		name: "c2"
		hashKey:  "id"
		combineTableTo: "combined_hash"

		attributes: [
			{ key: "title", type: "string", required: true }
		]

# create instance
sdManager = new SimpleDynamo( connectionSettings, tables )

# connect
sdManager.connect ( err )->
	console.log( "simple-dynamo ready to use" )
```

### First connect to AWS:

The module has to know about the existing AWS tables so you have to read them first.  
**If you do not run `.connect()` the module will throw an error everytime** 

**`Manager.connect( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method. Single arguments on return is the error object. On success the error is `null`
 
**Example**

```
sdManager.connect ( err )->
	if err
		console.error( "connect ERROR", err )
	else
		console.log( "simple-dynamo ready to use" )
```

### Create all tables:

to create all missing tables just call `.createAll()`.

This is not necessary if you know the tables has been created in the past.

**Note! The generating of tables could take a few Minutes**

**`Manager.generateAll( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method. Single arguments on return is the error object. On success the error is `null`

**Example**

```
sdManager.generateAll ( err )->
	if err
		console.error( "connect ERROR", err )
	else
		console.log( "simple-dynamo ready to use" )
```

### Get a table instance ( Table GET ):

To interact with a table you have to retrieve the table object. It's defined in the table-definitions

**`Manager.get( 'tableName' )` Arguments** : 

- **tableName**: *( `String` required )*  
Method to retrieve the instance of a table object.

**Example**

```
tblTodos = sdManager.get( 'Todos' )
```

### Destroy a table ( Table DESTROY ):

destroy table at AWS. This removes the table from AWS will all the data

**`Table.destroy( fnCallback )` Arguments** : 

- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`

**Example**

```
tblTodos.del ( err )->
	if err
		console.error( "destroy ERROR", err )
	else
		console.log( "table destroyed" )
```

### Write a new item ( INSERT ):

Create a new item in a select table. You can also add some attributes not defined in the table-definition, which will be saved, too.

**`Table.set( data, options, fnCallback )` Arguments** : 

- **data**: *( `Object` required )*  
The data to save. You can define the hash and/or range key. If not the module will generate a hash/range automatically.  
*Note:* If the used table uses the combined feature and you define the hash-key it's necessary to add the `name` out of the table-config in front of every hash.
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive
  - **overwriteExistingHash**: *( `Boolean` optional: default = true )*  Overwrite a item it already exists. 
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the save item as simple object

**Example**

```
data = 
	title: "My First Todo"
	done: 0
	aditionalData: "Foo bar"
	
tblTodos.set data, ( err, todo )->
	if err
		console.error( "insert ERROR", err )
	else
		console.log( todo )
```

### Get a item ( GET ):

Get an existing element by id/hash

**`Table.get( id, fnCallback )` Arguments** : 

- **id**: *( `String|Number` required )*  
The id of an element.
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive  
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the database item as simple object. If not found `null`

**Example**

```
tblTodos.get 'myTodoId', ( err, todo )->
	if err
		console.error( "get ERROR", err )
	else
		console.log( todo )
```

### Update an item ( UPDATE ):

update an existing item.  
An item always will be replaced. This means, if you remove some elements, the will be removed from the db, too

**`Table.set( id, data, options, fnCallback )` Arguments** : 

- **id**: *( `String|Number` required )*  
The id of an element.
- **data**: *( `Object` required )*  
The data to update. You can redefine the range key. If you pass the hash key it will be ignored
- **options**: *( `Object` optional )*  
For update you can define some options.
  - **removeMissing**: On `true` all keys not found in data will be removed. Otherwise it won't be touched.
  - **fields**: *( `Array` )* An array of fields to receive
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **item**: the database item as simple object. If not found `null`

**Example**

```
data = 
	title: "My First Update"
	done: 1
	
tblTodos.set 'myTodoId', data, ( err, todo )->
	if err
		console.error( "update ERROR", err )
	else
		# note. the key 'aditionalData' will be gone
		console.log( todo )
```

### Delete an item ( DELETE ):

delete an item by id/hash

**`Table.del( id, fnCallback )` Arguments** : 

- **id**: *( `String|Number` required )*  
The id of an element.
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`

**Example**

```
tblTodos.del 'myTodoId', ( err )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "delete done" )
```

### Query a table ( FIND ):

run a query on a table. The module automatically trys to do a `Dynamo.db scan` or `Dynamo query`.

**`Table.find( query, startAt, options, fnCallback )` Arguments** : 

- **query**: *( `Object` : default = `{}` all )*  
A query object. How to build … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
- **startAt**: *( `String|Number` optional )*  
To realize a paging you can define a `startAt`. Usually the last item of a list. If you define `startAt` with the last item of the previous find you get the next collection of items without the given `startAt` item
- **options**: *( `Object` optional )*  
  - **fields**: *( `Array` )* An array of fields to receive
  - **limit**: *( `Number` )* Define the max. items to return
- **fnCallback**: *( `Function` required )*  
Callback method.  
**Method Arguments**  
  - **err**: Usually `null`. On an error a object with `error` and `msg`
  - **items**: an array of objects found
	

**Example**

```
tblTodos.find {}, ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "all existend items", items )
```
**Advanced Examples**

```
# create a query to read all todos from last hour
_query = 
	id: { "!=": null }
	_t: { "<": ( Date.now() - ( 1000 * 60 * 60 ) ) }

tblTodos.find , ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "found items", items )
```

```
# read 4 todos from last hour beginning starting with a known id
_query = 
	id: { "!=": null }
	_t: { "<": ( Date.now() - ( 1000 * 60 * 60 ) ) }

_startAt = "myid_todoItem12"

_options = { "limit": 4, "fields": [ "id", "_t", "title" ] }

tblTodos.find _query, _startAt, _options, ( err, items )->
	if err
		console.error( "delete ERROR", err )
	else
		console.log( "4 found items", items )
```


### Working with sets ( UPDATE Set ):

Dynamo has the ability to work with sets. That means you can save a Set of Strings as an Array.  
During an update you have the ability to add or remove a single value out of the set. Or you can reset the whole set.  

But you can only perform one action per key and you obnly can use the functionalty if defined through the table-definition ( `type:"array"` ).

Existing values will be ignored.

The following key variants are availible:

- `"key":[ "a", "b", "c" ]'`: Resets the whole value of the key
- `"key":{ "$add": [ "d", "e" ] }`: Add some values to the set
- `"key":{ "$rem": [ "a", "b" ] }`: remove some values
- `"key":{ "$reset": [ "x", "y" ] }`: reset the whole value. Same as `"key":[ "x", "y" ]'`

**Examples**

```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: [ "x", "y", "z" ]

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "x", "y", "z" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$add": [ "a", "d", "e" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "a", "b", "c", "d", "e" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$rem": [ "a", "b", "x" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "c" ]"
    console.log( setData )
```
```
# Source "key: [ "a", "b", "c" ]"

data = 
    key: { "$reset": [ "x", "y", "z" ] }

tblSets.set 'mySetsId', data, ( err, setData )->
    # Result "key: [ "x", "y", "z" ]"
    console.log( setData )
```

## Todos

- `Tabel.mget( [ id1, id, .. ] )` Add a mget mehtod for batch get
- handle `throughput exceed`with a retry

## Work in progress

`simple-dynamo` is work in progress. Your ideas, suggestions etc. are very welcome.

## License 

(The MIT License)

Copyright (c) 2010 TCS &lt;dev (at) tcs.de&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.