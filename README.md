simple-dynamo
===========

**simple-dynamo** is a abstraction layer to Jed Schmidt's [dynamo](https://github.com/jed/dynamo) Node.js driver.

It provides a absolute simple JSON-CRUD Interface without any knowledge of Dynamos specialties.

*Written in coffee-script*

**INFO: all examples are written in coffee-script**

## Install

```
  npm install simple-dynamo@git://github.com/mpneuried/dynamo_connector.git
```

Or just require the `node_cache.js` file to get the superclass

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
  Datatype. possible values are `string` = String and `number` = Numeric
  - **key**: *( `Boolean` optional: default = `false` )*  
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
		hashKey:  "id"

		attributes: [
			{ key: "name", type: "string", required: true }
			{ key: "email", type: "string" }
		]
		
	"Todos":
		name: "todos"
		hashKey:  "id"
		rangeKey:  "_t"
		rangeKeyType:  "N"
		
		fnCreateHash: ( attributes, cb )=>
			cb( attributes.user_id )
			return
		
		attributes: [
			{ key: "title", type: "string", required: true }
			{ key: "done", type: "number" }
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

**Note! The generating of tables could take a time**

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

### Write a new item ( INSERT ):

Create a new item in a select table. You can also add some attributes not defined in the table-definition, which will be saved, too.

**`Table.set( data, fnCallback )` Arguments** : 

- **data**: *( `Object` required )*  
The data to save. You can define the hash and/or range key. If not the module will generate a hash/range automatically.
- **fnCallback**: *( `String` required )*  
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
- **fnCallback**: *( `String` required )*  
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

**`Table.set( id, data, fnCallback )` Arguments** : 

- **id**: *( `String|Number` required )*  
The id of an element.
- **data**: *( `Object` required )*  
The data to update. You can redefine the range key. If you pass the hash key it will be ignored
- **fnCallback**: *( `String` required )*  
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
- **fnCallback**: *( `String` required )*  
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

**`Table.find( query, fnCallback )` Arguments** : 

- **query**: *( `Object` required )*  
A query object. How to build … have a look at [Jed's Predicates ](https://github.com/jed/dynamo/wiki/High-level-API#wiki-predicates)
- **fnCallback**: *( `String` required )*  
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
		console.log( "found items", items )
```
**Advanced Example**

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


### Destroy a table ( Table DESTROY ):

destroy table at AWS. This removes the table from AWS will all the data

**`Table.destroy( fnCallback )` Arguments** : 

- **fnCallback**: *( `String` required )*  
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