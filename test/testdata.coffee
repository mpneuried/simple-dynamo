module.exports = 
	"Employees": 
		"insert1": { id:"1234567890", name: "First employee", email: "first@employee.com", age: 20 }
		"insert2": { name: "Second employee", email: "second@employee.com", age: 30, additional: "more ... " }
		"insert3": { name: "Third employee", email: "third@employee.com", age: 78 }

		"update2": { name: "Second employee Update", email: "second@employee.com", age: 35 }

	"Todos": 
		"insert1": { id: "123456", title: "First", done: 0 }
		"insert2": { id: "123456", title: "Second", done: 0  }

	"Rooms": 
		"insert1": { name: "First", users: [ "a" ] }
		"update1": { name: "First", users: [ "a", "b" ] }
		"update2": { name: "First", users: { "$add": [ "b", "c" ] } }
		"update3": { name: "First", users: { "$rem": [ "a" ] } }
		"update4": { name: "First", users: { "$reset": [ "x", "y" ] } }
		"update5": { name: "First", users: { "$add": "z" } }
		"update6": { name: "First", users: { "$rem": "x" } }
		"update7": { name: "First", users: { "$reset": "y" } }

	"Logs1": 
		"inserts": [
			{ t: 1, title: "1: I", user: "A" }
			{ t: 2, title: "1: II", user: "A" }
			{ t: 3, title: "1: III", user: "B" }
			{ t: 4, title: "1: IV", user: "A" }
			{ t: 5, title: "1: V", user: "C" }
			{ t: 6, title: "1: VI", user: "B" }
			{ t: 7, title: "1: VII", user: "A" }
			{ t: 8, title: "1: VIII", user: "C" }
			{ t: 9, title: "1: IX", user: "B" }
			{ t: 10, title: "1: X", user: "A" }
			{ t: 11, title: "1: XI", user: "D" }
			{ t: 12, title: "1: XII", user: "A" }
		]

	"Logs2": 
		"inserts": [
			{ t: 1, title: "2: I", user: "A" }
			{ t: 2, title: "2: II", user: "A" }
			{ t: 3, title: "2: III", user: "B" }
			{ t: 4, title: "2: IV", user: "A" }
			{ t: 5, title: "2: V", user: "C" }
			{ t: 6, title: "2: VI", user: "B" }
			{ t: 7, title: "2: VII", user: "A" }
			{ t: 8, title: "2: VIII", user: "C" }
			{ t: 9, title: "2: IX", user: "B" }
			{ t: 10, title: "2: X", user: "A" }
			{ t: 11, title: "2: XI", user: "D" }
			{ t: 12, title: "2: XII", user: "A" }
		]

	"C_Employees": 
		"insert1": { id:"emp1234567890", name: "First employee", email: "first@employee.com", age: 20 }
		"insert2": { name: "Second employee", email: "second@employee.com", age: 30, additional: "more ... " }
		"insert3": { name: "Third employee", email: "third@employee.com", age: 78 }
		"insert4": { id:"9999999", name: "Invalid employee", email: "invalid@employee.com", age: 99 }

		"update2": { name: "Second employee Update", email: "second@employee.com", age: 35 }

	"C_Todos": 
		"insert1": { id: "tds12345678911", title: "First", done: 0 }

		"insert2": { id: "tds12345678911", title: "Second", done: 0  }

	"C_Rooms": 
		"insert1": { name: "C_First", users: [ "a" ] }
		"update1": { name: "C_First", users: [ "a", "b" ] }
		"update2": { name: "C_First", users: { "$add": [ "b", "c" ] } }
		"update3": { name: "C_First", users: { "$rem": [ "a" ] } }
		"update4": { name: "C_First", users: { "$reset": [ "x", "y" ] } }
		"update5": { name: "First", users: { "$add": "z" } }
		"update6": { name: "First", users: { "$rem": "x" } }
		"update7": { name: "First", users: { "$reset": "y" } }

	"C_Logs1": 
		"inserts": [
			{ t: 1, title: "1: I", user: "A" }
			{ t: 2, title: "1: II", user: "A" }
			{ t: 3, title: "1: III", user: "B" }
			{ t: 4, title: "1: IV", user: "A" }
			{ t: 5, title: "1: V", user: "C" }
			{ t: 6, title: "1: VI", user: "B" }
			{ t: 7, title: "1: VII", user: "A" }
			{ t: 8, title: "1: VIII", user: "C" }
			{ t: 9, title: "1: IX", user: "B" }
			{ t: 10, title: "1: X", user: "A" }
			{ t: 11, title: "1: XI", user: "D" }
			{ t: 12, title: "1: XII", user: "A" }
		]

	"C_Logs2": 
		"inserts": [
			{ t: 1, title: "2: I", user: "A" }
			{ t: 2, title: "2: II", user: "A" }
			{ t: 3, title: "2: III", user: "B" }
			{ t: 4, title: "2: IV", user: "A" }
			{ t: 5, title: "2: V", user: "C" }
			{ t: 6, title: "2: VI", user: "B" }
			{ t: 7, title: "2: VII", user: "A" }
			{ t: 8, title: "2: VIII", user: "C" }
			{ t: 9, title: "2: IX", user: "B" }
			{ t: 10, title: "2: X", user: "A" }
			{ t: 11, title: "2: XI", user: "D" }
			{ t: 12, title: "2: XII", user: "A" }
		]