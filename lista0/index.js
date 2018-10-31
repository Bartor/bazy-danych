const {Creator} = require('./modules/creator');
const {courses} = require('./modules/creator');
const {inspect} = require('util');
const fs = require('fs');

// let creator = new Creator();
// let students = [creator.generatePlan('Kuba', 5), creator.generatePlan('Wojtek', 5), creator.generatePlan('Pies', 5)];
// console.log(inspect(students, {depth: null, colors: true}));
// fs.writeFile('students.json', JSON.stringify(students), (err) => {
//     console.log(err);
// });
let students;

fs.readFile('students.json', (err, data) => {
    if(err) {
        console.log(err);
        process.exit();
    } else {
        students = JSON.parse(data);
        successCallback();
    }
});

function successCallback() {
    console.log(inspect(students, {depth: null, colors: true}));
    let ans1 = '', ans2 = {}, ans3 = {}, ans4 = {};
    for (let student of students) {
        ans1 += `${student.name}:\n`;
        for (let course of student.courses) {
            ans2[course.name] = 0;
            (ans3.hasOwnProperty(course.place) ? ans3[course.place] += 1 : ans3[course.place] = 1);
            (ans4.hasOwnProperty(course.lecturer) ? ans4[course.lecturer] += 1 : ans4[course.lecturer] = 1);
            ans1 += `${course.name}, `;
        }
        ans1 += '\n';
    }
    let ans3Arr = [], ans4Arr = [];
    for(let property in ans3) {
        if(ans3.hasOwnProperty(property)) ans3Arr.push([property, ans3[property]]);
    }
    for(let property in ans4) {
        if(ans4.hasOwnProperty(property)) ans4Arr.push([property, ans4[property]]);
    }
    ans3Arr.sort((a, b) => (b[1] - a[1]));
    ans4Arr.sort((a, b) => (b[1] - a[1]));
    console.log(`1: ${ans1}`);
    console.log(`2: ${Object.keys(ans2)}`);
    console.log(`3: ${inspect(ans3Arr, {depth: null})}`);
    console.log(`4: ${ans4Arr[0][0]}`);
}