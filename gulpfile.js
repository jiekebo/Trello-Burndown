var gulp = require('gulp');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');
var coffeelint = require('gulp-coffeelint');
var changed = require('gulp-changed');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var bowerFiles = require('gulp-bower-files');

var express = require('express');
var livereload = require('gulp-livereload');
var lr = require('tiny-lr');

var server = lr();

var options = {
  // Coffee sources
  COFFEE_SOURCE : "coffee/**/*.coffee",
  COFFEE_DEST : "public",

   // Live reload
  LIVE_RELOAD_PORT : 35729,
  EXPRESS_PORT : 8080,
  EXPRESS_ROOT : "public"
}

gulp.task('lint', function () {
  gulp.src( options.COFFEE_SOURCE )
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
});

gulp.task('coffee', function() {
  gulp.src( options.COFFEE_SOURCE )
    .pipe(changed( options.COFFEE_SOURCE ))
    .pipe(coffee({
      sourceMap : true
    })
    .on('error', gutil.log))
    .pipe(gulp.dest( options.COFFEE_DEST ))
    .pipe(livereload( server ))
  gulp.src( options.COFFEE_SOURCE)
    .pipe(gulp.dest( options.COFFEE_DEST ))
});

gulp.task('bower', function() {
  bowerFiles()
    .pipe(concat('lib.js'))
    .pipe(gulp.dest("public"));
});

gulp.task('express', function() {
  var app = express();
  app.use(require('connect-livereload')());
  app.use(express.static(options.EXPRESS_ROOT));
  app.listen(options.EXPRESS_PORT);
});

gulp.task('default', ['bower', 'coffee', 'express'], function () {
  server.listen( options.LIVE_RELOAD_PORT , function (err) {
    if (err) {
      return console.log(err)
    };
    gulp.watch( options.COFFEE_SOURCE , ['coffee','lint'] );
  });
});