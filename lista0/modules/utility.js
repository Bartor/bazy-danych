 module.exports = {
     /***
      * Shuffle an array suing Knuth shuffle
      * @param arr Input array
      * @returns {*} Shuffled array
      */
     randomizeArray: function (arra1) {
         let ctr = arra1.length, temp, index;
         while (ctr > 0) {
             index = Math.floor(Math.random() * ctr);
             ctr--;
             temp = arra1[ctr];
             arra1[ctr] = arra1[index];
             arra1[index] = temp;
         }
         return arra1;
     },
 };