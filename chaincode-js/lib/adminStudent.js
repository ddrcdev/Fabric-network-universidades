/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

// Deterministic JSON.stringify()
const stringify  = require('json-stringify-deterministic');
const sortKeysRecursive  = require('sort-keys-recursive');
const { Contract } = require('fabric-contract-api');

class adminStudent extends Contract {

    async InitLedger(ctx) {
        const students = [
            {
                ID: '12345678',
                Degree: 'Master',
                Field: 'Engineering',
                Major: 'Civil Engineering',
                State: 4,
                ECTS: 220
                },                
                {
                ID: '87654321',
                Degree: 'Bachelor',
                Field: 'Science',
                Major: 'Computer Science',
                State: 3,
                ECTS: 190
                },                
                {
                ID: '56789012',
                Degree: 'Doctorate',
                Field: 'Medicine',
                Major: 'Neurology',
                State: 2,
                ECTS: 150
                },                
                {
                ID: '90123456',
                Degree: 'Bachelor',
                Field: 'Arts',
                Major: 'Graphic Design',
                State: 4,
                ECTS: 210
                },                
                {
                ID: '34567890',
                Degree: 'Master',
                Field: 'Literature',
                Major: 'English Literature',
                State: 1,
                ECTS: 60
                },                
                {
                ID: '65432109',
                Degree: 'Bachelor',
                Field: 'Journalism',
                Major: 'Broadcast Journalism',
                State: 3,
                ECTS: 180
                }
        ];

        for (const student of students) {
            student.docType = 'student';
            // example of how to write to world state deterministically
            // use convetion of alphabetic order
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            // when retrieving data, in any lang, the order of data will be the same and consequently also the corresonding hash
            await ctx.stub.putState(student.ID, Buffer.from(stringify(sortKeysRecursive(student))));
        }
    }

    // CreateStudent issues a new student to the world state with given details.
    async EnrollStudent(ctx, id, degree, size, major, state,ects) {
        const exists = await this.StudentExists(ctx, id);
        if (exists) {
            throw new Error(`The student ${id} already exists`);
        }

        const student = {
            ID: id,
            Degree: degree,
            Field: size,
            Major: major,
            State: state,
            ECTS: ects
        };
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(student))));
        return JSON.stringify(student);
    }

    // ReadStudent returns the student stored in the world state with given id.
    async ReadStudent(ctx, id) {
        const studentJSON = await ctx.stub.getState(id); // get the student from chaincode state
        if (!studentJSON || studentJSON.length === 0) {
            throw new Error(`The student ${id} does not exist`);
        }
        return studentJSON.toString();
    }

    // UpdateStudent updates an existing student in the world state with provided parameters.
    async UpdateStudent(ctx, id, degree, size, major, state,ects) {
        const exists = await this.StudentExists(ctx, id);
        if (!exists) {
            throw new Error(`The student ${id} does not exist`);
        }

        // overwriting original student with new student
        const updatedStudent = {
            ID: id,
            Degree: degree,
            Field: size,
            Major: major,
            State: state,
            ECTS: ects
        };
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        return ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(updatedStudent))));
    }

    // DeleteStudent deletes an given student from the world state.
    async DeleteStudent(ctx, id) {
        const exists = await this.StudentExists(ctx, id);
        if (!exists) {
            throw new Error(`The student ${id} does not exist`);
        }
        return ctx.stub.deleteState(id);
    }

    // StudentExists returns true when student with given ID exists in world state.
    async StudentExists(ctx, id) {
        const studentJSON = await ctx.stub.getState(id);
        return studentJSON && studentJSON.length > 0;
    }

    // TransferStudent updates the major field of student with given id in the world state.
    async TransferStudent(ctx, id, newMajor) {
        const studentString = await this.ReadStudent(ctx, id);
        const student = JSON.parse(studentString);
        const oldMajor = student.Major;
        student.Major = newMajor;
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(student))));
        return oldMajor;
    }

    // GetAllStudents returns all students found in the world state.
    async GetAllStudents(ctx) {
        const allResults = [];
        // range query with empty string for startKey and endKey does an open-ended query of all students in the chaincode namespace.
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            allResults.push(record);
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}

module.exports = StudentTransfer;
