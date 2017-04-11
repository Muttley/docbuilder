// using built-in methods
var start = new Date();

// the event to time goes here:
doSomethingForALongTime();
var end = new Date();
var elapsed = end.getTime() - start.getTime(); // elapsed time in milliseconds
