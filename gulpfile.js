var gulp = require('gulp'),
    jisp = require('gulp-jisp'),
    plumber = require('gulp-plumber');

gulp.task('scripts', function(){
    gulp.src('**/*.jisp').pipe(plumber()).pipe(jisp()).pipe(gulp.dest('./build'));
});
gulp.task('html', function(){
    gulp.src('./index.html').pipe(gulp.dest('./build'));
});

gulp.task('watch', function() {
  gulp.watch("**/*.jisp", ['scripts']);
  gulp.watch("./index.html", ['html']);
});

gulp.task('default', ["watch", "scripts", "html"])
