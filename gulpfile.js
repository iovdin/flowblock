var gulp = require('gulp'),
    jisp = require('gulp-jisp'),
    plumber = require('gulp-plumber'),
    livereload = require('gulp-livereload');

gulp.task('scripts', function(){
    gulp.src('**/*.jisp').pipe(plumber()).pipe(jisp()).pipe(gulp.dest('./'));
});

gulp.task('watch', function() {
  gulp.watch("**/*.jisp", ['scripts']);
});

gulp.task('default', ["watch", "scripts"])
