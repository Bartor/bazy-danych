const lecturers = ['Jan Paweł II', 'Józef Piłsudski', 'Karol Wojtyła', 'Kim Jong Un', 'Krzysztof Gonciarz'];
const courses   = ['AM1', 'AM2', 'ALGEBRA1', 'ALGEBRA2', 'LOGIKA', 'TP', 'KP'];
const places    = ['C13', 'C7', 'A1'];
const {randomizeArray} = require('./utility');

/***
 * Generates random courses
 * @param lecturersArray Available lecturers
 * @param coursesArray Available courses
 * @param placesArray Available places
 * @returns {Array} Array of creates lectures
 */
const createCourses = function(lecturersArray, coursesArray, placesArray) {
    if(lecturersArray.length > coursesArray.length) throw 'We want our all lecturers to work, duh';
    lecturersArray = randomizeArray(lecturersArray);
    coursesArray   = randomizeArray(coursesArray);
    let courses = [];
    let days = ['pn', 'wt', 'sr', 'cz', 'pt'];
    for(let [index, course] of coursesArray.entries()) {
        courses.push({
            name: course,
            time: { //we assume that lectures just start and go on for some time, they can also overlap
                day: days[Math.floor(Math.random()*days.length)],
                hour: Math.floor(Math.random()*10) + 7
            },
            place: placesArray[Math.floor(Math.random()*placesArray.length)],
            lecturer: lecturersArray[index % lecturersArray.length]
        });
    }
    return courses;
};

const Creator = function() {
    this.courses = createCourses(lecturers, courses, places);
};

Creator.prototype.generatePlan = function(name, minCoursesCount) {
    let plan = {name: name};
    plan.courses = randomizeArray(this.courses).slice(Math.floor(Math.random() * (this.courses.length - minCoursesCount)));
    return plan;
};

module.exports = {Creator, courses};